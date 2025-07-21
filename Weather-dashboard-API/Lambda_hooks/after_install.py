"""
CodeDeploy Hook: After Install
This function is called after the install phase of a CodeDeploy deployment.
"""

import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda handler for the after_install CodeDeploy hook
    """
    
    # Log the incoming event
    logger.info(f"After Install Hook - Event: {json.dumps(event)}")
    
    # Get CodeDeploy client
    codedeploy = boto3.client('codedeploy')
    
    # Extract deployment information
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    try:
        # Custom logic after install
        logger.info(f"Executing after_install hook for deployment: {deployment_id}")
        
        # Add your custom post-installation logic here
        # For example: configuration validation, health checks, etc.
        
        # Example: Validate that services are running
        # You could add ECS service checks here
        
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
                'message': 'After install hook completed successfully',
                'deploymentId': deployment_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error in after_install hook: {str(e)}")
        
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
