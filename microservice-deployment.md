
# MicroService Deployment Steps

### Docker file creation
* Create a Docker file under your main microservice
Example : ```data-reporting-service/person-service/Dockerfile```

### Create a service repository in ECR
* Open a ticket with foundations team to create a repository for the microservice.
  * Reference ticket : https://cdc-nbs.atlassian.net/browse/CNAT-168

### Update the GitHub Actions file
* Edit and update the GitHub Actions Workflow file in the root of the repository
  * ```.github/workflows/Build-and-deploy-reporting-services.yaml ```
  * Make a section under `jobs` for the new microservice
  * Update the name of the action,  microservice_name and dockerfile_relative_path
  * In the on.push.branches section give a private branch name and test if checkins trigger a docker image build and publish to ECR
  
### Helm Charts Update
* Create Helm Charts for the microservice in the https://github.com/CDCgov/NEDSS-Helm/ repository
  * Reference Person Reporting service as an example : https://github.com/CDCgov/NEDSS-Helm/tree/main/charts/person-reporting-service
  * Make sure to Update the environment variable values in the deployment.yaml, values.yaml and values-dts1.yaml
  * In the modernization-api [ingress](https://github.com/CDCgov/NEDSS-Helm/blob/main/charts/modernization-api/templates/ingress.yaml) add a section to your microservice entrypoint.

### Service deployment to EKS using ArgoCd
* Refer here for accessing ArgoCD : 
  * [ArgoCD setup](https://cdc-nbs.atlassian.net/wiki/spaces/NM/pages/664207380/SpringBoot+Java+MicroService+Deployment+Steps#Service-deployment-to-EKS-using-ArgoCd)
* In ArgoCD, create a new App
  * Edit the yaml to copy and paste the scripts from : 
    * [ArgoCD deployment yaml](https://enquizit.sharepoint.com/sites/CDCNBSProject/Shared%20Documents/Forms/AllItems.aspx)
  * Refer the following file :
    * [Person Service deployment](https://enquizit.sharepoint.com/:u:/r/sites/CDCNBSProject/Shared%20Documents/General/NBS%20Infrastructure/ArgoCD%20Deployments/dts1/person-reporting-service.yaml)
  * Update the name and helm environment variables as appropriate
  * Service should be published to the DTS1 EKS cluster


###  Organization Service DTS1 deployment :

- [Health Check](https://app.dts1.nbspreview.com/reporting/organization-svc/status)

### Person Service DTS1 deployment:
- [Health Check](https://app.dts1.nbspreview.com/reporting/person-svc/status)

### DTS1 Microservice CloudWatch Logs
- [CloudWatach Logs ](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/fluent-bit-cloudwatch)
  - Search for the respective microservice in log streams (Eg: person-service)
  