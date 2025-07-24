#!/usr/bin/env python3
"""
S3 Bucket Cleanup Script
Completely removes S3 buckets including all versions, delete markers, and multipart uploads.
"""

import boto3
import sys
import time
from botocore.exceptions import ClientError, NoCredentialsError
from typing import List, Dict, Any

# Import config for consistent bucket naming
try:
    from config import get_config, get_bucket_names as config_get_bucket_names
except ImportError:
    print("❌ Could not import config.py. Please ensure config.py exists.")
    sys.exit(1)

def get_bucket_names(environment: str) -> Dict[str, str]:
    """Generate bucket names for the given environment using config."""
    config = get_config()
    return config_get_bucket_names(environment, config)

def confirm_deletion(buckets: Dict[str, str], environment: str) -> bool:
    """Ask user for confirmation before deletion."""
    print("🚨 WARNING: This will permanently delete the following S3 buckets and ALL their contents:")
    print(f"   Environment: {environment}")
    for bucket_type, bucket_name in buckets.items():
        print(f"   - {bucket_name} ({bucket_type})")
    print("\nThis action cannot be undone!")
    
    confirmation = input("\nAre you sure you want to proceed? Type 'DELETE' to confirm: ")
    return confirmation == 'DELETE'

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
    """Delete all current objects (non-versioned)."""
    try:
        print("      ├── Deleting current objects...")
        paginator = s3_client.get_paginator('list_objects_v2')
        delete_count = 0
        
        for page in paginator.paginate(Bucket=bucket_name):
            if 'Contents' in page:
                objects_to_delete = [{'Key': obj['Key']} for obj in page['Contents']]
                if objects_to_delete:
                    s3_client.delete_objects(
                        Bucket=bucket_name,
                        Delete={'Objects': objects_to_delete}
                    )
                    delete_count += len(objects_to_delete)
        
        if delete_count > 0:
            print(f"         └── Deleted {delete_count} current objects")
        return True
    except ClientError as e:
        print(f"         └── Error deleting current objects: {e}")
        return False

def delete_all_versions_and_markers(s3_client, bucket_name: str) -> bool:
    """Delete all object versions and delete markers."""
    try:
        print("      ├── Deleting object versions and delete markers...")
        paginator = s3_client.get_paginator('list_object_versions')
        total_deleted = 0
        
        for page in paginator.paginate(Bucket=bucket_name):
            objects_to_delete = []
            
            # Add all versions
            if 'Versions' in page:
                for version in page['Versions']:
                    objects_to_delete.append({
                        'Key': version['Key'],
                        'VersionId': version['VersionId']
                    })
            
            # Add all delete markers
            if 'DeleteMarkers' in page:
                for marker in page['DeleteMarkers']:
                    objects_to_delete.append({
                        'Key': marker['Key'],
                        'VersionId': marker['VersionId']
                    })
            
            # Delete in batches of 1000 (AWS limit)
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
        
        if total_deleted > 0:
            print(f"         └── Deleted {total_deleted} versions and delete markers")
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

def get_bucket_stats(s3_client, bucket_name: str) -> Dict[str, int]:
    """Get current bucket statistics."""
    try:
        # Count current objects
        paginator = s3_client.get_paginator('list_objects_v2')
        current_objects = 0
        for page in paginator.paginate(Bucket=bucket_name):
            current_objects += len(page.get('Contents', []))
        
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
            'versions': versions,
            'delete_markers': delete_markers,
            'multipart_uploads': multipart_uploads
        }
    except ClientError:
        return {
            'current_objects': 0,
            'versions': 0,
            'delete_markers': 0,
            'multipart_uploads': 0
        }

def cleanup_bucket(s3_client, bucket_name: str) -> bool:
    """Completely clean up and delete a bucket."""
    print(f"📦 Processing bucket: {bucket_name}")
    
    if not bucket_exists(s3_client, bucket_name):
        print("   └── ⚠️  Bucket does not exist or is not accessible")
        return False
    
    print("   ├── Bucket exists, proceeding with cleanup...")
    
    # Get initial stats
    initial_stats = get_bucket_stats(s3_client, bucket_name)
    total_initial = sum(initial_stats.values())
    
    if total_initial == 0:
        print("   ├── Bucket is already empty")
    else:
        print(f"   ├── Found {initial_stats['current_objects']} objects, "
              f"{initial_stats['versions']} versions, "
              f"{initial_stats['delete_markers']} delete markers, "
              f"{initial_stats['multipart_uploads']} multipart uploads")
    
    # Try force deletion first
    print("   ├── Attempting force removal...")
    try:
        s3_client.delete_bucket(Bucket=bucket_name)
        print("   └── ✅ Successfully deleted bucket (was already empty)")
        return True
    except ClientError:
        print("   ├── Force removal failed, performing detailed cleanup...")
    
    # Detailed cleanup
    max_attempts = 3
    for attempt in range(1, max_attempts + 1):
        print(f"   ├── Cleanup attempt {attempt} of {max_attempts}...")
        
        # Delete current objects
        if not delete_all_objects(s3_client, bucket_name):
            continue
        
        # Delete versions and markers
        if not delete_all_versions_and_markers(s3_client, bucket_name):
            continue
        
        # Abort multipart uploads
        if not abort_multipart_uploads(s3_client, bucket_name):
            continue
        
        # Check if bucket is now empty
        current_stats = get_bucket_stats(s3_client, bucket_name)
        total_remaining = sum(current_stats.values())
        
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
                time.sleep(2)
            else:
                print("      └── Max cleanup attempts reached")
                print("   └── ❌ Failed to completely clean bucket")
                return False
    
    # Try to delete the bucket
    print("   ├── Attempting final bucket deletion...")
    try:
        s3_client.delete_bucket(Bucket=bucket_name)
        print("   └── ✅ Successfully deleted bucket")
        return True
    except ClientError as e:
        print(f"   └── ❌ Failed to delete bucket: {e}")
        
        # Final troubleshooting
        final_stats = get_bucket_stats(s3_client, bucket_name)
        total_final = sum(final_stats.values())
        if total_final > 0:
            print(f"      └── Bucket still contains {total_final} items")
        else:
            print("      └── Bucket appears empty but deletion failed (may have access restrictions)")
        return False

def main():
    """Main function."""
    if len(sys.argv) != 2:
        print("Usage: python destroy_s3_buckets.py <environment>")
        print("Example: python destroy_s3_buckets.py dev")
        print("         python destroy_s3_buckets.py staging")
        print("         python destroy_s3_buckets.py prod")
        sys.exit(1)
    
    environment = sys.argv[1]
    region = "us-east-2"
    
    # Get bucket names
    buckets = get_bucket_names(environment)
    
    # Confirm deletion
    if not confirm_deletion(buckets, environment):
        print("❌ Operation cancelled. Buckets were not deleted.")
        sys.exit(0)
    
    # Initialize S3 client
    try:
        s3_client = boto3.client('s3', region_name=region)
        # Test credentials
        s3_client.list_buckets()
    except NoCredentialsError:
        print("❌ AWS credentials not found. Please configure your credentials.")
        sys.exit(1)
    except ClientError as e:
        print(f"❌ Error initializing S3 client: {e}")
        sys.exit(1)
    
    print(f"\n🧹 Starting bucket cleanup process for environment: {environment}...")
    
    # Process each bucket
    results = {}
    for bucket_type, bucket_name in buckets.items():
        results[bucket_type] = cleanup_bucket(s3_client, bucket_name)
        print()  # Add spacing between buckets
    
    # Summary
    print("🎯 Cleanup process completed!")
    print(f"\n📋 Summary for environment: {environment}")
    for bucket_type, bucket_name in buckets.items():
        status = "✅ Deleted" if results[bucket_type] else "❌ Failed"
        print(f"   - {bucket_name} ({bucket_type}): {status}")
    
    # Exit with appropriate code
    if all(results.values()):
        print("\n✨ All buckets were successfully deleted.")
        sys.exit(0)
    else:
        print("\n⚠️  Some buckets could not be deleted. Manual intervention may be required.")
        sys.exit(1)

if __name__ == "__main__":
    main()
