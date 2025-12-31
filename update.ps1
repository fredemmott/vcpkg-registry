# Copyright 2025 Fred Emmott <fred@fredemmott.com>
# SPDX-License-Identifier: MIT

# Assumptions:
#  - port has (and reads from) a  version.json with 'repo' and 'branch' properties
#  - you want the latest commit, not a release
#  - you're using `version-date` in your vcpkg file
[CmdletBinding()]
param(
  [Parameter(Mandatory=$True)]
  [String]$Port,
  [ValidateSet("Release", "HEAD")]
  [string]$Source
)
$ConfigPath = "ports/${Port}/version.json"
$Config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
$Repo = $Config.repo

$VcpkgPath= "ports/${Port}/vcpkg.json"
$Vcpkg = Get-Content $VcpkgPath | ConvertFrom-Json -Depth 10 -AsHashtable

if ($Source -ne 'HEAD' -and ($Config.release -or $Source -eq "Release"))
{
  $Commit = $( gh api /repos/${Repo}/releases -q '[.[] | select(.prerelease == false)].[0].tag_name' )
  $Config.release = $Commit

  $Config.Remove('commit')
  foreach ($Key in $Vcpkg.keys.Clone()) {
    if ($Key -match 'version-*') {
      $Vcpkg.Remove($Key)
    }
  }
  $Vcpkg.'version-semver' = $Commit -replace '^v',''
} else {
  $Endpoint = "repos/${Repo}/commits?per_page=1"
  if ($Config.branch)
  {
    $Endpoint += "&sha=$($Config.branch)"
  }
  $CommitData = $(gh api "${Endpoint}" -q '.[0]') | ConvertFrom-Json
  $Commit = $CommitData.sha
  $Config.commit = $Commit
  $CommitDate = $CommitData.commit.committer.date.ToString('yyyy-MM-dd')

  if ((-not $Vcpkg.'version-date') -or -not ($Vcpkg.'version-date'.StartsWith($CommitDate))) {
    $Vcpkg.'version-date' = $CommitDate;
  } elseif ($Vcpkg['version-date'] -eq $CommitDate) {
    $Vcpkg.'version-date' = "${CommitDate}.1"
  } else {
    $PreviousVersion = [int] $Vcpkg.'version-date'.split('.')[1]
    $Version = $PreviousVersion + 1
    $Vcpkg.'version-date' = "${CommitDate}.${Version}"
  }

  if ($Config.release) {
    $Config.Remove('release')
  }

  foreach ($Key in $Vcpkg.keys.Clone()) {
    if ($Key -match 'version-*' -and -not ($Key -eq 'version-date')) {
      $Vcpkg.Remove($Key)
    }
  }
}

ConvertTo-Json $Vcpkg -Depth 10 | Set-Content $VcpkgPath -Encoding utf8NoBom
vcpkg format-manifest $VcpkgPath

$TarballURL = "https://github.com/${Repo}/archive/${Commit}.tar.gz"

$WebRequest = Invoke-WebRequest -Uri $TarballURL -UseBasicParsing

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
git commit versions -m "Update versions/ for ${Port}@${Commit}"
$EndRev = $(git rev-parse HEAD)
git log --patch "${StartRev}..${EndRev}"
echo "git log --patch `"${StartRev}..${EndRev}`""
