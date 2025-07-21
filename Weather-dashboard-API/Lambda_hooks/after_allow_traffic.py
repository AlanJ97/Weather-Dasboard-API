"""
CodeDeploy Hook: After Allow Traffic
This function is called after traffic has been allowed to the new deployment.
"""

import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda handler for the after_allow_traffic CodeDeploy hook
    """
    
    # Log the incoming event
    logger.info(f"After Allow Traffic Hook - Event: {json.dumps(event)}")
    
    # Get AWS clients
    codedeploy = boto3.client('codedeploy')
    
    # Extract deployment information
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    try:
        # Custom logic after allowing traffic
        logger.info(f"Executing after_allow_traffic hook for deployment: {deployment_id}")
        
        # Add your custom post-traffic logic here
        # For example: monitoring setup, notifications, cleanup, etc.
        
        # Example: Log successful deployment
        logger.info(f"Traffic successfully switched for deployment: {deployment_id}")
        
        # You could add:
        # - Slack/SNS notifications
        # - Monitoring setup
        # - Post-deployment validations
        # - Cleanup of old resources
        
        # Signal success to CodeDeploy
        if lifecycle_event_hook_execution_id:
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=deployment_id,
                lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
                status='Succeeded'
            )
            logger.info("Successfully notified CodeDeploy of hook completion")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'After allow traffic hook completed successfully',
                'deploymentId': deployment_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error in after_allow_traffic hook: {str(e)}")
        
        # Signal failure to CodeDeploy
        if lifecycle_event_hook_execution_id:
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=deployment_id,
                lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
                status='Failed'
            )
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'deploymentId': deployment_id
            })
        }
