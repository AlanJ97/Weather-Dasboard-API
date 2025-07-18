import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    CodeDeploy AfterInstall hook
    This function runs after the new ECS task definition is installed
    """
    
    logger.info(f"AfterInstall hook triggered for environment: ${environment}")
    logger.info(f"Event: {json.dumps(event, indent=2)}")
    
    # Extract CodeDeploy information from the event
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    codedeploy = boto3.client('codedeploy')
    
    try:
        # Perform any post-installation validation here
        # For example: configuration validation, service checks, etc.
        
        logger.info("AfterInstall validation passed")
        
        # Report success to CodeDeploy
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=deployment_id,
            lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            status='Succeeded'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps('AfterInstall hook completed successfully')
        }
        
    except Exception as e:
        logger.error(f"AfterInstall hook failed: {str(e)}")
        
        # Report failure to CodeDeploy
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=deployment_id,
            lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            status='Failed'
        )
        
        return {
            'statusCode': 500,
            'body': json.dumps(f'AfterInstall hook failed: {str(e)}')
        }
