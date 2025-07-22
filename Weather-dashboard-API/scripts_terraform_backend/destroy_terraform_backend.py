#!/usr/bin/env python3
"""
Terraform Backend S3 Bucket Cleanup Script
Completely removes the Terraform backend S3 bucket including all state files, versions, delete markers, and multipart uploads.
This should be the LAST script to run after destroying all Terraform infrastructure.
"""

import boto3
import sys
import time
from botocore.exceptions import ClientError, NoCredentialsError
from typing import Dict

# Import config for consistent bucket naming
try:
    from config import get_config, get_terraform_backend_bucket
except ImportError:
    print("❌ Could not import config.py. Please ensure config.py exists.")
    sys.exit(1)

# Get bucket configuration from config file
config = get_config()
BUCKET_NAME = get_terraform_backend_bucket(config)
AWS_REGION = config['aws_region']

def confirm_deletion() -> bool:
    """Ask user for confirmation before deletion."""
    print("🚨 CRITICAL WARNING: This will permanently delete the Terraform backend bucket and ALL state files!")
    print(f"   Bucket: {BUCKET_NAME}")
    print(f"   Region: {AWS_REGION}")
    print("\n⚠️  This will DELETE ALL TERRAFORM STATE FILES!")
    print("   Make sure you have destroyed all Terraform infrastructure first!")
    print("   This action cannot be undone!")
    
    confirmation = input("\nAre you absolutely sure you want to proceed? Type 'DELETE_BACKEND' to confirm: ")
    return confirmation == 'DELETE_BACKEND'

def bucket_exists(s3_client, bucket_name: str) -> bool:
    """Check if bucket exists and is accessible."""
    try:
        s3_client.head_bucket(Bucket=bucket_name)
        return True
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '404':
            return False
        elif error_code == '403':
            print(f"   └── ❌ Access denied to bucket: {bucket_name}")
            return False
        else:
            print(f"   └── ❌ Error checking bucket {bucket_name}: {e}")
            return False

def delete_all_objects(s3_client, bucket_name: str) -> bool:
    """Delete all current objects (non-versioned) with Object Lock bypass."""
    try:
        print("      ├── Deleting current objects...")
        paginator = s3_client.get_paginator('list_objects_v2')
        delete_count = 0
        bypassed_count = 0
        
        for page in paginator.paginate(Bucket=bucket_name):
            if 'Contents' in page:
                for obj in page['Contents']:
                    # Show what state files are being deleted
                    if obj['Key'].endswith('.tfstate'):
                        print(f"         ├── Deleting Terraform state: {obj['Key']}")
                    elif obj['Key'].endswith('.tflock'):
                        print(f"         ├── Deleting Terraform lock: {obj['Key']}")
                    
                    try:
                        # Try normal delete first
                        s3_client.delete_object(
                            Bucket=bucket_name,
                            Key=obj['Key']
                        )
                        delete_count += 1
                    except ClientError as e:
                        if 'AccessDenied' in str(e):
                            try:
                                # Try with governance bypass
                                s3_client.delete_object(
                                    Bucket=bucket_name,
                                    Key=obj['Key'],
                                    BypassGovernanceRetention=True
                                )
                                delete_count += 1
                                bypassed_count += 1
                            except ClientError as bypass_error:
                                print(f"         ├── Failed to delete protected object {obj['Key']}: {bypass_error}")
                        else:
                            print(f"         ├── Error deleting {obj['Key']}: {e}")
        
        if delete_count > 0:
            print(f"         └── Deleted {delete_count} current objects")
            if bypassed_count > 0:
                print(f"         └── Bypassed Object Lock governance on {bypassed_count} objects")
        return True
    except ClientError as e:
        print(f"         └── Error deleting current objects: {e}")
        return False

def delete_all_versions_and_markers(s3_client, bucket_name: str) -> bool:
    """Delete all object versions and delete markers with Object Lock bypass."""
    try:
        print("      ├── Deleting object versions and delete markers...")
        paginator = s3_client.get_paginator('list_object_versions')
        total_deleted = 0
        state_files_deleted = 0
        bypassed_count = 0
        
        for page in paginator.paginate(Bucket=bucket_name):
            objects_to_delete = []
            protected_objects = []
            
            # Separate regular objects from potentially protected ones
            if 'Versions' in page:
                for version in page['Versions']:
                    if version['Key'].endswith('.tfstate'):
                        # State files might be protected by Object Lock
                        protected_objects.append({
                            'Key': version['Key'],
                            'VersionId': version['VersionId']
                        })
                        state_files_deleted += 1
                    else:
                        objects_to_delete.append({
                            'Key': version['Key'],
                            'VersionId': version['VersionId']
                        })
            
            # Add all delete markers (usually not protected)
            if 'DeleteMarkers' in page:
                for marker in page['DeleteMarkers']:
                    objects_to_delete.append({
                        'Key': marker['Key'],
                        'VersionId': marker['VersionId']
                    })
            
            # Try bulk delete for non-protected objects first
            if objects_to_delete:
                batch_size = 1000
                for i in range(0, len(objects_to_delete), batch_size):
                    batch = objects_to_delete[i:i + batch_size]
                    try:
                        response = s3_client.delete_objects(
                            Bucket=bucket_name,
                            Delete={'Objects': batch}
                        )
                        deleted_count = len(response.get('Deleted', []))
                        total_deleted += deleted_count
                        
                        if response.get('Errors'):
                            print(f"         ├── Batch had {len(response['Errors'])} errors")
                            for error in response['Errors'][:3]:  # Show first 3 errors
                                print(f"         │   └── {error.get('Code', 'Unknown')}: {error.get('Key', 'Unknown key')}")
                        
                    except ClientError as e:
                        print(f"         ├── Error deleting batch: {e}")
                        return False
            
            # Handle protected objects individually with governance bypass
            for obj in protected_objects:
                try:
                    # First try normal delete
                    s3_client.delete_object(
                        Bucket=bucket_name,
                        Key=obj['Key'],
                        VersionId=obj['VersionId']
                    )
                    total_deleted += 1
                    bypassed_count += 1
                except ClientError as e:
                    if 'AccessDenied' in str(e):
                        try:
                            # Try with governance bypass
                            s3_client.delete_object(
                                Bucket=bucket_name,
                                Key=obj['Key'],
                                VersionId=obj['VersionId'],
                                BypassGovernanceRetention=True
                            )
                            total_deleted += 1
                            bypassed_count += 1
                        except ClientError as bypass_error:
                            print(f"         ├── Failed to delete protected object {obj['Key']}: {bypass_error}")
                    else:
                        print(f"         ├── Error deleting {obj['Key']}: {e}")
        
        if total_deleted > 0:
            print(f"         └── Deleted {total_deleted} versions and delete markers")
            if state_files_deleted > 0:
                print(f"         └── Including {state_files_deleted} Terraform state file versions")
            if bypassed_count > 0:
                print(f"         └── Bypassed Object Lock governance on {bypassed_count} objects")
        return True
    except ClientError as e:
        print(f"         └── Error deleting versions/markers: {e}")
        return False

def abort_multipart_uploads(s3_client, bucket_name: str) -> bool:
    """Abort any incomplete multipart uploads."""
    try:
        print("      ├── Aborting multipart uploads...")
        paginator = s3_client.get_paginator('list_multipart_uploads')
        abort_count = 0
        
        for page in paginator.paginate(Bucket=bucket_name):
            if 'Uploads' in page:
                for upload in page['Uploads']:
                    try:
                        s3_client.abort_multipart_upload(
                            Bucket=bucket_name,
                            Key=upload['Key'],
                            UploadId=upload['UploadId']
                        )
                        abort_count += 1
                    except ClientError as e:
                        print(f"         ├── Error aborting upload {upload['Key']}: {e}")
        
        if abort_count > 0:
            print(f"         └── Aborted {abort_count} multipart uploads")
        return True
    except ClientError as e:
        print(f"         └── Error aborting multipart uploads: {e}")
        return False

def bypass_object_lock_retention(s3_client, bucket_name: str) -> bool:
    """Try to bypass object lock retention by removing individual object retention."""
    try:
        print("      ├── Checking Object Lock configuration...")
        
        # Check if Object Lock is enabled
        try:
            response = s3_client.get_object_lock_configuration(Bucket=bucket_name)
            print("         ├── Object Lock is enabled")
            print("         ├── Attempting to bypass object-level retention...")
            
            # Try to remove object retention on protected objects
            paginator = s3_client.get_paginator('list_object_versions')
            bypass_count = 0
            
            for page in paginator.paginate(Bucket=bucket_name):
                if 'Versions' in page:
                    for version in page['Versions']:
                        try:
                            # Try to remove object retention
                            s3_client.put_object_retention(
                                Bucket=bucket_name,
                                Key=version['Key'],
                                VersionId=version['VersionId'],
                                Retention={}
                            )
                            bypass_count += 1
                        except ClientError as retention_error:
                            # If we can't remove retention, try to bypass with governance mode
                            if 'AccessDenied' in str(retention_error):
                                try:
                                    s3_client.delete_object(
                                        Bucket=bucket_name,
                                        Key=version['Key'],
                                        VersionId=version['VersionId'],
                                        BypassGovernanceRetention=True
                                    )
                                    bypass_count += 1
                                except ClientError:
                                    pass  # Skip this version
                            else:
                                pass  # Skip this version
            
            if bypass_count > 0:
                print(f"         └── Bypassed retention on {bypass_count} objects")
            else:
                print("         └── Could not bypass retention - objects may need to wait for retention period")
            
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == 'ObjectLockConfigurationNotFoundError':
                print("         └── Object Lock is not enabled")
                return True
            else:
                print(f"         └── Error checking Object Lock: {e}")
                return True  # Continue anyway
    except ClientError as e:
        print(f"         └── Error checking Object Lock: {e}")
        return True  # Continue anyway

def get_bucket_stats(s3_client, bucket_name: str) -> Dict[str, int]:
    """Get current bucket statistics."""
    try:
        # Count current objects
        paginator = s3_client.get_paginator('list_objects_v2')
        current_objects = 0
        state_files = 0
        for page in paginator.paginate(Bucket=bucket_name):
            if 'Contents' in page:
                current_objects += len(page['Contents'])
                for obj in page['Contents']:
                    if obj['Key'].endswith('.tfstate'):
                        state_files += 1
        
        # Count versions and delete markers
        paginator = s3_client.get_paginator('list_object_versions')
        versions = 0
        delete_markers = 0
        for page in paginator.paginate(Bucket=bucket_name):
            versions += len(page.get('Versions', []))
            delete_markers += len(page.get('DeleteMarkers', []))
        
        # Count multipart uploads
        paginator = s3_client.get_paginator('list_multipart_uploads')
        multipart_uploads = 0
        for page in paginator.paginate(Bucket=bucket_name):
            multipart_uploads += len(page.get('Uploads', []))
        
        return {
            'current_objects': current_objects,
            'state_files': state_files,
            'versions': versions,
            'delete_markers': delete_markers,
            'multipart_uploads': multipart_uploads
        }
    except ClientError:
        return {
            'current_objects': 0,
            'state_files': 0,
            'versions': 0,
            'delete_markers': 0,
            'multipart_uploads': 0
        }

def cleanup_terraform_backend() -> bool:
    """Completely clean up and delete the Terraform backend bucket."""
    print(f"🗂️  Processing Terraform backend bucket: {BUCKET_NAME}")
    
    # Initialize S3 client
    try:
        s3_client = boto3.client('s3', region_name=AWS_REGION)
        # Test credentials
        s3_client.list_buckets()
    except NoCredentialsError:
        print("❌ AWS credentials not found. Please configure your credentials.")
        return False
    except ClientError as e:
        print(f"❌ Error initializing S3 client: {e}")
        return False
    
    if not bucket_exists(s3_client, BUCKET_NAME):
        print("   └── ✅ Terraform backend bucket does not exist - nothing to clean up")
        return True
    
    print("   ├── Terraform backend bucket exists, proceeding with cleanup...")
    
    # Get initial stats
    initial_stats = get_bucket_stats(s3_client, BUCKET_NAME)
    total_initial = sum(initial_stats.values()) - initial_stats['state_files']  # Don't double-count state files
    
    if total_initial == 0:
        print("   ├── Bucket is already empty")
    else:
        print(f"   ├── Found {initial_stats['current_objects']} objects "
              f"(including {initial_stats['state_files']} Terraform state files), "
              f"{initial_stats['versions']} versions, "
              f"{initial_stats['delete_markers']} delete markers, "
              f"{initial_stats['multipart_uploads']} multipart uploads")
        
        if initial_stats['state_files'] > 0:
            print(f"   ⚠️  WARNING: This bucket contains {initial_stats['state_files']} Terraform state files!")
            print("   ⚠️  Make sure you have destroyed all infrastructure before proceeding!")
    
    # Try force deletion first
    print("   ├── Attempting force removal...")
    try:
        s3_client.delete_bucket(Bucket=BUCKET_NAME)
        print("   └── ✅ Successfully deleted Terraform backend bucket (was already empty)")
        return True
    except ClientError:
        print("   ├── Force removal failed, performing detailed cleanup...")
    
    # Detailed cleanup with more attempts for Object Lock
    max_attempts = 5  # More attempts for Object Lock scenarios
    for attempt in range(1, max_attempts + 1):
        print(f"   ├── Cleanup attempt {attempt} of {max_attempts}...")
        
        # Check Object Lock and try to bypass
        if not bypass_object_lock_retention(s3_client, BUCKET_NAME):
            continue
        
        # Delete current objects
        if not delete_all_objects(s3_client, BUCKET_NAME):
            continue
        
        # Delete versions and markers
        if not delete_all_versions_and_markers(s3_client, BUCKET_NAME):
            continue
        
        # Abort multipart uploads
        if not abort_multipart_uploads(s3_client, BUCKET_NAME):
            continue
        
        # Check if bucket is now empty
        current_stats = get_bucket_stats(s3_client, BUCKET_NAME)
        total_remaining = sum(current_stats.values()) - current_stats['state_files']
        
        if total_remaining == 0:
            print("      └── Bucket is now empty")
            break
        else:
            print(f"      ├── Still {total_remaining} items remaining "
                  f"({current_stats['current_objects']} objects, "
                  f"{current_stats['versions']} versions, "
                  f"{current_stats['delete_markers']} markers, "
                  f"{current_stats['multipart_uploads']} uploads)")
            
            if attempt < max_attempts:
                print("      ├── Waiting before next attempt...")
                if attempt <= 2:
                    time.sleep(3)  # Short wait for first attempts
                else:
                    time.sleep(10)  # Longer wait for Object Lock retention to potentially expire
                    print(f"      ├── Extended wait - Object Lock retention may need time to expire...")
            else:
                print("      └── Max cleanup attempts reached")
                print("   └── ❌ Failed to completely clean Terraform backend bucket")
                print("   └── 💡 Object Lock retention policy may be preventing deletion")
                print("   └── 💡 Wait for retention period to expire or contact AWS support")
                return False
    
    # Try to delete the bucket
    print("   ├── Attempting final bucket deletion...")
    try:
        s3_client.delete_bucket(Bucket=BUCKET_NAME)
        print("   └── ✅ Successfully deleted Terraform backend bucket")
        return True
    except ClientError as e:
        print(f"   └── ❌ Failed to delete Terraform backend bucket: {e}")
        
        # Final troubleshooting
        final_stats = get_bucket_stats(s3_client, BUCKET_NAME)
        total_final = sum(final_stats.values()) - final_stats['state_files']
        if total_final > 0:
            print(f"      └── Bucket still contains {total_final} items")
            if final_stats['state_files'] > 0:
                print(f"      └── Including {final_stats['state_files']} Terraform state files")
        else:
            print("      └── Bucket appears empty but deletion failed")
            print("      └── This may be due to Object Lock retention policy")
        return False

def main():
    """Main function."""
    print("🧹 Terraform Backend Cleanup Script")
    print("=====================================")
    print(f"Target: {BUCKET_NAME} (region: {AWS_REGION})")
    print()
    
    # Confirm deletion
    if not confirm_deletion():
        print("❌ Operation cancelled. Terraform backend bucket was not deleted.")
        sys.exit(0)
    
    print(f"\n🚨 Starting Terraform backend cleanup...")
    
    # Process the bucket
    success = cleanup_terraform_backend()
    
    # Summary
    print("\n🎯 Terraform backend cleanup completed!")
    
    if success:
        print("✅ Terraform backend bucket has been successfully deleted.")
        print("✅ All Terraform state files have been permanently removed.")
        print("✅ Infrastructure teardown is now complete!")
    else:
        print("❌ Failed to completely remove Terraform backend bucket.")
        print("⚠️  Manual intervention may be required.")
        print("💡 Try waiting a few minutes and running the script again.")
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
