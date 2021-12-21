param(
    [string]$repository = "vleschenko",
    [version]$minCalicoVersion = "3.19.0",
    [version]$minK8sVersion = "1.22.0"
)

pushd calico

Write-Host "build calico"
$calicoVersions = (curl -L https://api.github.com/repos/projectcalico/calico/releases | ConvertFrom-Json) | % tag_name
foreach($calicoVersion in $calicoVersions)
{
    if ($calicoVersion -match "^v(\d+\.\d+\.\d+)$")
    {
        $testVersion = [version]$Matches[1]
        if ($testVersion -ge $minCalicoVersion)
        {
            Write-Host "Build images for calico $calicoVersion"
            docker buildx build --platform windows/amd64 --output=type=registry --pull --build-arg=CALICO_VERSION=$calicoVersion -f ./install/Dockerfile.install -t $repository/calico-install:$calicoVersion-hostprocess ./install
            docker buildx build --platform windows/amd64 --output=type=registry --pull --build-arg=CALICO_VERSION=$calicoVersion -f ./node/Dockerfile.node -t $repository/calico-node:$calicoVersion-hostprocess ./node
        }
    }
}

Write-Host "build kube-proxy"
$versions = (curl -L k8s.gcr.io/v2/kube-proxy/tags/list | ConvertFrom-Json).tags
foreach($version in $versions)
{
    if ($version -match "^v(\d+\.\d+\.\d+)$")
    {
        $testVersion = [version]$Matches[1]
        if ($testVersion -ge $minK8sVersion)
        {
            Write-Host "Build image for kube-proxy $version"
            docker buildx build --platform windows/amd64 --output=type=registry --pull --build-arg=k8sVersion=$version -f ./kube-proxy/Dockerfile -t $repository/kube-proxy:$version-calico-hostprocess ./kube-proxy
        }
    }
}

popd
