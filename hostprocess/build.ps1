param(
    [string]$repository = "vleschenko",
    [version]$calicoVersion = "3.21.2",
    [version]$minK8sVersion = "1.22.0"
)

pushd calico
write-host "build calico"
./build.sh -r $repository --calicoVersion "v$calicoVersion"

write-host "build kube-proxy"
$versions = (curl -L k8s.gcr.io/v2/kube-proxy/tags/list | ConvertFrom-Json).tags
foreach($version in $versions)
{
    if ($version -match "^v(\d+\.\d+\.\d+)$")
    {
        $testVersion = [version]$Matches[1]
        if ($testVersion -ge $minK8sVersion)
        {
            ./build.sh -r $repository --proxyVersion $version
        }
        else
        {
            Write-Host "Skip $version because it less than $minK8sVersion."
        }
    }
    else
    {
        Write-Host "Skip $version because it isn't release version."
    }
}

popd
