# defender-cicd-demo

Demo repository showing Microsoft Security DevOps (IaC scanning) in a GitHub Actions
pipeline, followed by an optional Bicep deployment to Azure.

The workflow lives in [`.github/workflows/ci-cd-security.yml`](.github/workflows/ci-cd-security.yml).

## Azure OIDC login

The `Sign in to Azure with OIDC` step uses [`azure/login`](https://github.com/Azure/login)
with workload identity federation (no client secret). It only runs when the
`AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID` secrets are all set,
so the security scanning part of the pipeline still runs in forks or before Azure is
configured.

### Troubleshooting `AADSTS700213`

```
Login failed with Error: The process '/usr/bin/az' failed with exit code 1.
AADSTS700213: No matching federated identity record found for presented assertion
subject 'repo:<owner>/<repo>:ref:refs/heads/main'.
```

This means the login itself reached Entra ID, but the app registration has no federated
identity credential matching the token GitHub presented. Fix it on the Azure side:

1. In the Azure portal go to **Microsoft Entra ID → App registrations → your app →
   Certificates & secrets → Federated credentials → Add credential**.
2. Choose scenario **GitHub Actions deploying Azure resources**.
3. Set:
   - **Organization**: `Saheba01`
   - **Repository**: `defender-cicd-demo`
   - **Entity type**: `Branch`, **Branch**: `main`
     (add a second credential with entity type `Pull request` if you also deploy from PRs,
     and one per environment/tag you deploy from — one credential matches exactly one subject)
   - **Audience**: `api://AzureADTokenExchange`

   The resulting subject must match exactly what the workflow log prints under
   `subject claim`, e.g. `repo:Saheba01/defender-cicd-demo:ref:refs/heads/main`.
4. Give the app registration's service principal at least **Contributor** on the target
   resource group so `azure/arm-deploy` can deploy.

### Required repository configuration

| Name | Kind | Description |
| --- | --- | --- |
| `AZURE_CLIENT_ID` | secret | Application (client) ID of the app registration |
| `AZURE_TENANT_ID` | secret | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | secret | Target subscription ID |
| `AZURE_RESOURCE_GROUP` | variable (optional) | Target resource group, defaults to `demo-rg` |

Also keep `permissions: id-token: write` in the workflow — without it the runner cannot
request the OIDC token and login fails before it reaches Entra ID.
