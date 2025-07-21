"""
CodeDeploy Hook: Before Install
This function is called before the install phase of a CodeDeploy deployment.
"""

import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda handler for the before_install CodeDeploy hook
    """
    
    # Log the incoming event
    logger.info(f"Before Install Hook - Event: {json.dumps(event)}")
    
    # Get CodeDeploy client
    codedeploy = boto3.client('codedeploy')
    
    # Extract deployment information
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    try:
        # Custom logic before install
        logger.info(f"Executing before_install hook for deployment: {deployment_id}")
        
        # Add your custom pre-installation logic here
        # For example: validation checks, backup operations, etc.
        
        # Example: Log deployment details
        if deployment_id:
            deployment_info = codedeploy.get_deployment(deploymentId=deployment_id)
            logger.info(f"Deployment info: {json.dumps(deployment_info['deploymentInfo'], default=str)}")
        
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
                'message': 'Before install hook completed successfully',
                'deploymentId': deployment_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error in before_install hook: {str(e)}")
        
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
