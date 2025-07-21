"""
CodeDeploy Hook: After Install
Simple minimal implementation.
"""

import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Simple handler for after_install
    """
    logger.info("AfterInstall hook executed successfully")
    
    # Get required parameters
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    try:
        # Signal success to CodeDeploy
        if lifecycle_event_hook_execution_id:
            codedeploy = boto3.client('codedeploy')
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
        logger.error(f"Error: {str(e)}")
        
        # Signal failure to CodeDeploy
        if lifecycle_event_hook_execution_id:
            codedeploy = boto3.client('codedeploy')
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=deployment_id,
                lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
                status='Failed'
            )
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
