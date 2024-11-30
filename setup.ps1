$executionPolicies = Get-ExecutionPolicy -List

if ($executionPolicies.Process -ne 'RemoteSigned') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
}

if ($executionPolicies.CurrentUser -ne 'RemoteSigned') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

Get-ExecutionPolicy -List

exit 0

# Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
