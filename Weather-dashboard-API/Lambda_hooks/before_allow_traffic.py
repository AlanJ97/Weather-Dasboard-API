"""
CodeDeploy Hook: Before Allow Traffic
This function is called before allowing traffic to the new deployment.
"""

import json
import boto3
import logging
import time

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda handler for the before_allow_traffic CodeDeploy hook
    """
    
    # Log the incoming event
    logger.info(f"Before Allow Traffic Hook - Event: {json.dumps(event)}")
    
    # Get AWS clients
    codedeploy = boto3.client('codedeploy')
    ecs = boto3.client('ecs')
    
    # Extract deployment information
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    try:
        # Custom logic before allowing traffic
        logger.info(f"Executing before_allow_traffic hook for deployment: {deployment_id}")
        
        # Add your custom pre-traffic logic here
        # For example: health checks, warming up services, etc.
        
        # Example: Wait a few seconds for services to stabilize
        logger.info("Allowing services to stabilize before traffic switch...")
        time.sleep(5)
        
        # Example: You could add ECS service health checks here
        # Check if tasks are running and healthy
        
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
                'message': 'Before allow traffic hook completed successfully',
                'deploymentId': deployment_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error in before_allow_traffic hook: {str(e)}")
        
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
