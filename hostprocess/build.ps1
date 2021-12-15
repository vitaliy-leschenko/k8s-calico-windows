param(
    [string]$repository = "vleschenko",
    [version]$calicoVersion = "3.21.2",
    [version]$minK8sVersion = "1.22.0"
)

docker buildx create --name img-builder --use --platform windows/amd64

pushd calico
write-host "build calico"
pushd install
docker buildx build --platform windows/amd64 --output=type=registry --pull --build-arg=CALICO_VERSION=v$calicoVersion -f Dockerfile.install -t $repository/calico-install:v$calicoVersion-hostprocess .
popd
pushd node
docker buildx build --platform windows/amd64 --output=type=registry --pull --build-arg=CALICO_VERSION=v$calicoVersion -f Dockerfile.node -t $repository/calico-node:v$calicoVersion-hostprocess .
popd

write-host "build kube-proxy"
pushd kube-proxy
$versions = (curl -L k8s.gcr.io/v2/kube-proxy/tags/list | ConvertFrom-Json).tags
foreach($version in $versions)
{
    if ($version -match "^v(\d+\.\d+\.\d+)$")
    {
        $testVersion = [version]$Matches[1]
        if ($testVersion -ge $minK8sVersion)
        {
            Write-Host "Build $version"
            docker buildx build --platform windows/amd64 --output=type=registry --pull --build-arg=k8sVersion=$version -f Dockerfile -t $repository/kube-proxy:$version-calico-hostprocess .
        }
    }
}
popd

popd
