# Copyright 2025 Fred Emmott <fred@fredemmott.com>
# SPDX-License-Identifier: MIT

# Assumptions:
#  - port has (and reads from) a  version.json with 'repo' and 'branch' properties
#  - you want the latest commit, not a release
#  - you're using `version-date` in your vcpkg file
#
# TODO: support tagged releases instead, via an option in the `version.json` file
$Port = 'fredemmott-gui'
$ConfigPath = "ports/${Port}/version.json"
$Config = Get-Content $ConfigPath | ConvertFrom-Json
$Repo = $Config.repo
$CommitData = $(gh api /repos/${Repo}/commits?per_page=1 -q '.[0]') | ConvertFrom-Json
$Commit = $CommitData.sha
$CommitDate = $CommitData.commit.committer.date.ToString('yyyy-MM-dd')
$TarballURL = "https://github.com/${Repo}/archive/${commit}.tar.gz"

$VcpkgPath= "ports/${Port}/vcpkg.json"
$Vcpkg = Get-Content $VcpkgPath | ConvertFrom-Json -Depth 10
if (-not ($Vcpkg.'version-date'.StartsWith($CommitDate))) {
  $Vcpkg.'version-date' = $CommitDate;
} elseif ($Vcpkg['version-date'] -eq $CommitDate) {
  $Vcpkg.'version-date' = "${CommitDate}.1"
} else {
  $PreviousVersion = [int] $Vcpkg.'version-date'.split('.')[1]
  $Version = $PreviousVersion + 1
  $Vcpkg.'version-date' = "${CommitDate}.${Version}"
}
ConvertTo-Json $Vcpkg -Depth 10 | Set-Content $VcpkgPath -Encoding utf8NoBom
vcpkg format-manifest $VcpkgPath

$WebRequest = Invoke-WebRequest -Uri $TarballURL -UseBasicParsing

$Config.Commit = $Commit
$Config.sha512 = (Get-FileHash -InputStream $WebRequest.RawContentStream -Algorithm "SHA512").Hash.ToLower()
(ConvertTo-Json $Config).Replace("`r`n","`n") | Set-Content $ConfigPath -Encoding utf8NoBOM

$StartRev = $(git rev-parse HEAD)
git add "ports/${Port}"
git commit "ports/${Port}" -m "Update ${Port} to ${Commit}"

vcpkg `
  --x-builtin-ports-root=./ports `
  --x-builtin-registry-versions-dir=./versions `
  x-add-version `
  --all --verbose

git add versions
git commit versions -m "Update versions/ for ${Port}@{$Commit}"
$EndRev = $(git rev-parse HEAD)
git log --patch "${StartRev}..${EndRev}"
echo "git log --patch `"${StartRev}..${EndRev}`""
