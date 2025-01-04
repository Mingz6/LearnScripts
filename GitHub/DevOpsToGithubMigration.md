# Migrating Project from Azure DevOps to GitHub and Setting up Deployment on Azure

Below are the steps to help ensure a smooth transition:

## Plan Refinement and Additional Steps:

1. **Create a New Repo in GitHub (e.g., `myapp`)**:
   - Ensure you have the necessary permissions to create repositories under the GitHub account or organization.
   - Initialize the repository with a README, .gitignore file (appropriate for your project's language/framework), and a license if needed.

2. **Add a new remote origin to the DevOps repo**:
   - Run `git remote -v` to verify.

3. **Push Existing Code from the Old Repo to the New Repo Origin**:
   - Run `git push <neworigin> master:main`.

4. **Create a New Resource Group (`myapp-test`) Under the Subscription**:
   - You can do this via Azure CLI, PowerShell, or the Azure Portal.
   - Ensure your account has the necessary permissions to create resource groups and resources within the Subscription.

5. **Create New App Registrations in Azure for Deployment**:
   - Register a new app application as "myapp-test-deployment-Account" in Azure AD to create a service principal for deployments.
     ```
     az ad sp create --id <XXXXX-XXXXX-XXXXX>
     ```
   - Assign the necessary roles to the service principal, such as `Contributor` on the resource group where you'll be deploying.
     ```
     az role assignment create --role contributor --subscription <my-subscription> --assignee-object-id <object-id> --assignee-principal-type ServicePrincipal --scope /subscriptions/<my-subscription>/resourceGroups/myapp-test
     ```
   - Create a Client secret for testing Bicep deployment.

6. **Create Environments in GitHub to Store Secrets**:
   - Set up GitHub environments to segregate deployment secrets for different environments (e.g., prod, test, dev).
   - Configure environment secrets with Azure service principal credentials and any other required configuration values (e.g., AppId, SubscriptionId, TenantId).

7. **Start Creating CI and CD (Convert ARM to Bicep)**:
   - Log in with the deployment account using the Client secret:
     ```
     az login --service-principal -u <XXXXX-XXXXX-XXXXX> -p <my-password> --tenant <my-tenant-id>
     ```
   1. Create hostingPlanName and App-Insight with Bicep:
      ```
      az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/application-insights.bicep" --name "bicep-appinsights"
      ```
   2. Deploy Key Vault Bicep:
      a. Create Key Vault:
         ```
         az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/key-vault.bicep" --name "bicep-keyvault-$(date '+%Y%m%d%H%M%S')"
         ```
      b. Copy the secret using the AzPowerShell module.
         ```
         .\copySecrets.ps1 -sourceKvName "MingZAppVaultTest" -destKvName "kv-mingz-test"
         ```
   3. Create Storage Account:
      ```
      az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/storage-account.bicep" --name "storage-account-$(date '+%Y%m%d%H%M%S')"
      ```
   4. Assign Contributor role to the Resource Relay under the <shared-resources-group>:
      ```
      az role assignment create --assignee-object-id <my-subscription> --role "Contributor" --scope "/subscriptions/<my-subscription>/resourceGroups/<shared-resources-group>/providers/Microsoft.Relay/namespaces/sb-hc-domain"
      ```
   5. Create Function App with Bicep and deploy resources with Bicep:
      ```
      az deployment group create --resource-group myapp-test --subscription <my-subscription> --template-file "./main-stack/func-apps/template-myapp.bicep" --parameters "./main-stack/func-apps/params/bicep-myapp-params-test.json" --name "bicep-myapp-$(Get-Date -Format 'yyyyMMddHHmmss')"
      ```
   6. CI&CD function app code to Azure using GitHub actions:
      a. Download the publish profile from the Func App created in Step 5.
      b. Upload the publish profile to the GitHub secrets.
      c. Run the GitHub YAML file to deploy the build code to the function app.
   7. Create ARM to Bicep:
      - Convert ARM to Bicep using the following CLI:
        ```
        az bicep decompile --file <path_to_template.json>
        ```

   8. Create each Small component:
      a. Create Action Group:
         ```
         az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/action-group.bicep" --name "bicep-actiongroup-$(date '+%Y%m%d%H%M%S')"
         ```
      b. Create Alert Rules:
         ```
         az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/scheduled-query-rules.bicep" --name "bicep-scheduledqueryrules-$(date '+%Y%m%d%H%M%S')"
         ```

   10. Create CDN profiles:
       a. Assign contributor role to app-registration:
          ```
          az role assignment create --role contributor --subscription <my-subscription> --assignee-object-id <object-id> --assignee-principal-type ServicePrincipal --scope /subscriptions/<my-subscription>/resourceGroups/<shared-resources-group>
          ```
       b. Deploy Bicep:
          ```
          az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/cdn-profiles.bicep" --parameters "./core/params/cdn-profiles-params.json" --name "bicep-cdnprofiles"
          ```
       c. Add CNAME to the CDN profile.

   11. Upgrade App Service Plan (Enhancement):
       ```
       az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/app-service-plan.bicep" --name "bicep-appserviceplan-$(date '+%Y%m%d%H%M%S')"
       ```

   12. Rest app services:
       ```
       az role assignment create --role contributor --subscription <my-subscription> --assignee-object-id <object-id> --assignee-principal-type ServicePrincipal --scope /subscriptions/<my-subscription>/resourceGroups/finance-integration-dev
       ```
       ```
       az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/app-service.bicep" --parameters "./core/params/app-service-params.json" --parameters environmentName="dev" --name "bicep-appservice-$(date '+%Y%m%d%H%M%S')"
       ```

   13. Change all naming conventions to use the same naming convention.
   14. All CDN and CDNE are created by one cdn-profiles.bicep.
   15. Create Fun-App core (Base template for creating func-app).
   16. Upgrade func app to use fun-app core (Step #15):
       ```
       az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./main-stack/func-myapp.bicep" --parameters "./main-stack/params/func-myapp-params.json" --name "bicep-plannertasks-$(date '+%Y%m%d%H%M%S')"
       ```

   17. Test the main.bicep to deploy all resources at once:
       ```
       az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./main.bicep" --name "main-bicep-$(date '+%Y%m%d%H%M%S')" --parameters environmentName='dev'
       ```

   18. Upgrade storage account script with DeploymentScript. This allows blob container to enable static websites through Bicep now.
       a. Create managed identity for the deployment script and run the deployment script with managed identity:
          ```
          az deployment group create --resource-group myapp-dev --subscription <my-subscription> --template-file "./core/storage-account-setstaticweb.bicep" --name "bicep-setstaticweb-$(date '+%Y%m%d%H%M%S')"
          ```
       b. If running the deployment script fails, the "storage contributor" role is required and must be added to the managed identity. Ask an admin to do it:
          ```
          az role assignment create --assignee <Client-ID> --role "Storage Account Contributor" --scope /subscriptions/<my-subscription>/resourceGroups/myapp-dev
          ```

   19. Create a GitHub action to deploy Bicep script (call main.bicep to create & update all Azure resources at once).

   20. Create a GitHub action to build and deploy function app code:
       a. Create base YAML.
       b. Create function app YAML.
       c. Download the publish profile from the function app.
       d. Upload the publish profile to GitHub environment secrets.
       e. Run the GitHub action to deploy function app code.

   21. Create a GitHub action to build and upload Connect ReactJs:
       a. Get the storage account key from the storage account.
       b. Paste the storage account key into GitHub environment secrets.
       c. Use a YAML file to build and upload code to the storage account.

   22. Create a GitHub action to build and upload NetCore:
       a. Get the publish profile from the web app.
       b. Paste the publish profile into GitHub environment secrets.
       c. Use a YAML file to build and upload code to the web app.
       d. Swap staging and production slots (the action takes care of this).

   23. PR validation and send notifications (use actions or power automation to send notifications to teams).

   24. CI frontend coverage.

   25. CI backend coverage (if the app size is over 1GB, use a large runner to handle the task).

   26. CI frontend build and deployment.

   27. CI backend build and deployment.

   28. Function app build and deployment.

## Additional Considerations:

- **Documentation**: Update any documentation that references the old Azure DevOps setup to now point to the new processes and tooling.

- **Communication**: Inform your team about the migration and any new workflows or practices they need to follow.
