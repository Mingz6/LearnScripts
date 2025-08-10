

# PowerShell script to clear GitHub Actions workflow runs
param(
    [string]$Owner = "nursesabca",
    [string]$Repo = "enterprise-services",
    [string]$WorkflowId = "",
    [int]$MonthsOld = 3,
    [switch]$AutoDeleteOldRuns
)

# Set variables
$OWNER = $Owner
$REPO = $Repo

Write-Host "Repository: $OWNER/$REPO" -ForegroundColor Green

# List workflows
Write-Host "`nListing all workflows..." -ForegroundColor Yellow
$workflows = gh api -X GET "/repos/$OWNER/$REPO/actions/workflows" | ConvertFrom-Json
$workflows.workflows | ForEach-Object {
    Write-Host "Name: $($_.name)" -ForegroundColor Cyan
    Write-Host "ID: $($_.id)" -ForegroundColor White
    Write-Host "---"
}

# If WorkflowId is not provided, decide based on mode
if ([string]::IsNullOrEmpty($WorkflowId)) {
    if ($AutoDeleteOldRuns) {
        Write-Host "`nAuto-delete mode: Processing all workflows..." -ForegroundColor Yellow
        $WORKFLOW_ID = "ALL"
    } else {
        $WORKFLOW_ID = Read-Host "`nEnter the ID of the workflow you want to clear (or 'ALL' for all workflows)"
    }
} else {
    $WORKFLOW_ID = $WorkflowId
}

if ($WORKFLOW_ID -eq "ALL") {
    Write-Host "`nProcessing all workflows..." -ForegroundColor Green
} else {
    Write-Host "`nUsing Workflow ID: $WORKFLOW_ID" -ForegroundColor Green
}

# List runs for the specified workflow(s)
Write-Host "`nListing workflow runs..." -ForegroundColor Yellow

$allWorkflowRuns = @()

if ($WORKFLOW_ID -eq "ALL") {
    # Get runs from all workflows
    foreach ($workflow in $workflows.workflows) {
        Write-Host "Fetching runs for workflow: $($workflow.name) (ID: $($workflow.id))" -ForegroundColor Gray
        try {
            # Use pagination with per_page to handle large responses better
            $page = 1
            $perPage = 100
            do {
                $workflowRunsPage = gh api -X GET "/repos/$OWNER/$REPO/actions/workflows/$($workflow.id)/runs?page=$page&per_page=$perPage" | ConvertFrom-Json
                
                # Add workflow info to each run for easier lookup later
                foreach ($run in $workflowRunsPage.workflow_runs) {
                    $run | Add-Member -MemberType NoteProperty -Name "workflow_name" -Value $workflow.name -Force
                }
                
                $allWorkflowRuns += $workflowRunsPage.workflow_runs
                $page++
                
                # Break if we've gotten all runs or if there are no more
                if ($workflowRunsPage.workflow_runs.Count -lt $perPage) {
                    break
                }
                
                # Limit to prevent infinite loops - adjust as needed
                if ($page -gt 50) {
                    Write-Host "  Warning: Reached page limit for workflow $($workflow.id)" -ForegroundColor Yellow
                    break
                }
                
            } while ($workflowRunsPage.workflow_runs.Count -eq $perPage)
            
            Write-Host "  Found $($allWorkflowRuns.Count) total runs so far" -ForegroundColor Gray
        }
        catch {
            Write-Host "  Warning: Could not fetch runs for workflow $($workflow.id): $_" -ForegroundColor Yellow
        }
    }
} else {
    # Get runs from specific workflow
    try {
        # Use pagination for specific workflow as well
        $page = 1
        $perPage = 100
        do {
            $workflowRunsPage = gh api -X GET "/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs?page=$page&per_page=$perPage" | ConvertFrom-Json
            
            # Find the workflow name for this specific workflow
            $workflowInfo = $workflows.workflows | Where-Object { $_.id -eq [int]$WORKFLOW_ID }
            $workflowName = if ($workflowInfo) { $workflowInfo.name } else { "Unknown Workflow" }
            
            # Add workflow info to each run
            foreach ($run in $workflowRunsPage.workflow_runs) {
                $run | Add-Member -MemberType NoteProperty -Name "workflow_name" -Value $workflowName -Force
            }
            
            $allWorkflowRuns += $workflowRunsPage.workflow_runs
            $page++
            
            if ($workflowRunsPage.workflow_runs.Count -lt $perPage) {
                break
            }
            
            if ($page -gt 50) {
                Write-Host "  Warning: Reached page limit for workflow $WORKFLOW_ID" -ForegroundColor Yellow
                break
            }
            
        } while ($workflowRunsPage.workflow_runs.Count -eq $perPage)
    }
    catch {
        Write-Host "Error fetching runs for workflow ${WORKFLOW_ID}: $_" -ForegroundColor Red
        exit 1
    }
}

# Calculate the cutoff date for old runs (3 months ago by default)
$cutoffDate = (Get-Date).AddMonths(-$MonthsOld)
Write-Host "Cutoff date for old runs: $($cutoffDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

# Filter runs based on date
if ($AutoDeleteOldRuns) {
    Write-Host "Auto-delete mode: Only selecting runs older than $MonthsOld months" -ForegroundColor Yellow
    $filteredRuns = $allWorkflowRuns | Where-Object { 
        $runDate = [DateTime]::Parse($_.created_at)
        $runDate -lt $cutoffDate
    }
    $runIds = $filteredRuns | ForEach-Object { $_.id }
    
    Write-Host "Found $($allWorkflowRuns.Count) total workflow runs" -ForegroundColor White
    Write-Host "Found $($runIds.Count) workflow runs older than $MonthsOld months that will be deleted" -ForegroundColor Cyan
    
    if ($runIds.Count -gt 0) {
        Write-Host "`nOld runs to be deleted:" -ForegroundColor Yellow
        $filteredRuns | ForEach-Object {
            $runDate = [DateTime]::Parse($_.created_at)
            Write-Host "  - Workflow: $($_.workflow_name), Run ID: $($_.id), Created: $($runDate.ToString('yyyy-MM-dd HH:mm:ss')), Status: $($_.status)" -ForegroundColor Gray
        }
    }
} else {
    # Show all runs with age information
    $oldRuns = $allWorkflowRuns | Where-Object { 
        $runDate = [DateTime]::Parse($_.created_at)
        $runDate -lt $cutoffDate
    }
    
    Write-Host "Found $($allWorkflowRuns.Count) total workflow runs" -ForegroundColor White
    Write-Host "Found $($oldRuns.Count) runs older than $MonthsOld months" -ForegroundColor Cyan
    
    if ($oldRuns.Count -gt 0) {
        Write-Host "`nRuns older than $MonthsOld months:" -ForegroundColor Yellow
        $oldRuns | ForEach-Object {
            $runDate = [DateTime]::Parse($_.created_at)
            Write-Host "  - Workflow: $($_.workflow_name), Run ID: $($_.id), Created: $($runDate.ToString('yyyy-MM-dd HH:mm:ss')), Status: $($_.status)" -ForegroundColor Gray
        }
    }
    
    # Ask user what they want to delete
    Write-Host "`nWhat would you like to delete?" -ForegroundColor Yellow
    Write-Host "1. All runs ($($allWorkflowRuns.Count) runs)" -ForegroundColor White
    Write-Host "2. Only runs older than $MonthsOld months ($($oldRuns.Count) runs)" -ForegroundColor White
    Write-Host "3. Cancel" -ForegroundColor White
    
    do {
        $choice = Read-Host "Enter your choice (1-3)"
    } while ($choice -notin @('1', '2', '3'))
    
    switch ($choice) {
        '1' { 
            $runIds = $allWorkflowRuns | ForEach-Object { $_.id }
            Write-Host "Selected: All runs ($($runIds.Count) runs)" -ForegroundColor Green
        }
        '2' { 
            $runIds = $oldRuns | ForEach-Object { $_.id }
            Write-Host "Selected: Old runs only ($($runIds.Count) runs)" -ForegroundColor Green
        }
        '3' { 
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0 
        }
    }
}

if ($runIds.Count -eq 0) {
    Write-Host "No workflow runs found to delete." -ForegroundColor Yellow
    exit 0
}

# Confirm deletion
if (-not $AutoDeleteOldRuns) {
    $confirmation = Read-Host "`nAre you sure you want to delete the selected $($runIds.Count) workflow runs? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "`nAuto-delete mode enabled. Proceeding with deletion of old runs..." -ForegroundColor Yellow
}

# Delete runs
Write-Host "`nDeleting workflow runs..." -ForegroundColor Yellow
$deletedCount = 0
$failedCount = 0

foreach ($runId in $runIds) {
    try {
        gh api -X DELETE "/repos/$OWNER/$REPO/actions/runs/$runId" --silent
        $deletedCount++
        Write-Host "Deleted run ID: $runId" -ForegroundColor Green
    }
    catch {
        $failedCount++
        Write-Host "Failed to delete run ID: $runId - Error: $_" -ForegroundColor Red
    }
}

Write-Host "`nOperation completed!" -ForegroundColor Green
Write-Host "Successfully deleted: $deletedCount runs" -ForegroundColor Cyan
if ($failedCount -gt 0) {
    Write-Host "Failed to delete: $failedCount runs" -ForegroundColor Red
}