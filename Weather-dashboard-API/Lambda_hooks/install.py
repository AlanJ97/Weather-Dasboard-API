"""
CodeDeploy Hook: Install
This function is called during the install phase of a CodeDeploy deployment.
"""

import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda handler for the install CodeDeploy hook
    """
    
    # Log the incoming event
    logger.info(f"Install Hook - Event: {json.dumps(event)}")
    
    # Get CodeDeploy client
    codedeploy = boto3.client('codedeploy')
    
    # Extract deployment information
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    try:
        # Custom logic during install
        logger.info(f"Executing install hook for deployment: {deployment_id}")
        
        # Add your custom installation logic here
        # For example: deployment validation, custom installation steps, etc.
        
        # Example: Log that the installation is proceeding
        logger.info("Installation phase is proceeding successfully")
        
        # You could add:
        # - Custom validation of the deployment
        # - Additional installation steps
        # - Health checks during installation
        # - Progress monitoring
        
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
                'message': 'Install hook completed successfully',
                'deploymentId': deployment_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error in install hook: {str(e)}")
        
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
