import json
import boto3
import logging
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    CodeDeploy BeforeAllowTraffic hook
    This function runs before traffic is allowed to the new ECS tasks
    """
    
    logger.info("BeforeAllowTraffic hook triggered")
    logger.info(f"Event: {json.dumps(event, indent=2)}")
    
    # Extract CodeDeploy information from the event
    deployment_id = event.get('DeploymentId')
    lifecycle_event_hook_execution_id = event.get('LifecycleEventHookExecutionId')
    
    codedeploy = boto3.client('codedeploy')
    
    try:
        # Perform health checks on the new deployment
        # You can add your specific health check logic here
        
        # Example: Wait for services to be ready
        time.sleep(10)
        
        # Example: Health check endpoint (uncomment and modify as needed)
        # import urllib.request
        # health_check_url = "http://your-alb-endpoint/health"
        # response = urllib.request.urlopen(health_check_url, timeout=30)
        # if response.status != 200:
        #     raise Exception(f"Health check failed: {response.status}")
        
        logger.info("BeforeAllowTraffic validation passed")
        
        # Report success to CodeDeploy
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=deployment_id,
            lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            status='Succeeded'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps('BeforeAllowTraffic hook completed successfully')
        }
        
    except Exception as e:
        logger.error(f"BeforeAllowTraffic hook failed: {str(e)}")
        
        # Report failure to CodeDeploy
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=deployment_id,
            lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            status='Failed'
        )
        
        return {
            'statusCode': 500,
            'body': json.dumps(f'BeforeAllowTraffic hook failed: {str(e)}')
        }
