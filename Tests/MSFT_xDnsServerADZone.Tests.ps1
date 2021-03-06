if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..).Path

$ModuleName = 'MSFT_xDnsServerADZone'
Import-Module (Join-Path $RepoRoot "DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe 'xDnsServerADZone' {
    InModuleScope $ModuleName {

        ## Stub DnsServer module cmdlets
        function Get-DnsServerZone { }
        function Add-DnsServerPrimaryZone { param ( $Name ) }
        function Set-DnsServerPrimaryZone { [CmdletBinding()] param (
            $Name,
            $DynamicUpdate,
            $ReplicationScope,
            $DirectoryPartitionName,
            $CimSession ) }
        function Remove-DnsServerZone { }

        $testZoneName = 'example.com';
        $testDynamicUpdate = 'Secure';
        $testReplicationScope = 'Domain';
        $testDirectoryPartitionName = "DomainDnsZones.$testZoneName";
        $testParams = @{ Name = $testZoneName; }

        $fakeDnsADZone = [PSCustomObject] @{
            DistinguishedName = $null;
            ZoneName = $testZoneName;
            ZoneType = 'Primary';
            DynamicUpdate = $testDynamicUpdate;
            ReplicationScope = $testReplicationScope;
            DirectoryPartitionName = $testDirectoryPartitionName;
            ZoneFile = $null;
        }

        $fakePresentTargetResource = @{
            Name = $testZoneName
            DynamicUpdate = $testDynamicUpdate
            ReplicationScope = $testReplicationScope;
            DirectoryPartitionName = $testDirectoryPartitionName;
            Ensure = 'Present'
            CimSession = @{
                Id = 1
                Name = 'CimSession1'
                InstanceId = 'a23d4d49-f588-407d-9b78-601cd74d8116'
                ComputerName = 'localhost'
                Protocol = 'WSMAN'
            }
        }

        $fakeAbsentTargetResource = @{ Ensure = 'Absent' }

        Mock -CommandName 'Assert-Module' -MockWith { }

        Context 'Validates Get-TargetResource Method' {

            It 'Returns a "System.Collections.Hashtable" object type' {
                $targetResource = Get-TargetResource @testParams -ReplicationScope $testReplicationScope;
                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Returns "Present" when DNS zone exists and "Ensure" = "Present"' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsADZone; }
                $targetResource = Get-TargetResource @testParams -ReplicationScope $testReplicationScope;
                $targetResource.Ensure | Should Be 'Present';
            }

            It 'Returns "Absent" when DNS zone does not exists and "Ensure" = "Present"' {
                Mock -CommandName Get-DnsServerZone -MockWith { }
                $targetResource = Get-TargetResource @testParams -ReplicationScope $testReplicationScope;
                $targetResource.Ensure | Should Be 'Absent';
            }

            It 'Returns "Present" when DNS zone exists and "Ensure" = "Absent"' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsADZone; }
                $targetResource = Get-TargetResource @testParams -ReplicationScope $testReplicationScope -Ensure Absent;
                $targetResource.Ensure | Should Be 'Present';
            }

            It 'Returns "Absent" when DNS zone does not exist and "Ensure" = "Absent"' {
                Mock -CommandName Get-DnsServerZone -MockWith { }
                $targetResource = Get-TargetResource @testParams -ReplicationScope $testReplicationScope -Ensure Absent;
                $targetResource.Ensure | Should Be 'Absent';
            }

        } #end context Validates Get-TargetResource Method

        Context 'Validates Test-TargetResource Method' {

            It 'Returns a "System.Boolean" object type' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                $targetResource =  Test-TargetResource @testParams -ReplicationScope $testReplicationScope;
                $targetResource -is [System.Boolean] | Should Be $true;
            }

            It 'Passes when DNS zone exists and "Ensure" = "Present"' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope | Should Be $true;
            }

            It 'Passes when DNS zone does not exist and "Ensure" = "Absent"' {
                Mock -CommandName Get-TargetResource -MockWith {  }
                Test-TargetResource @testParams -Ensure Absent -ReplicationScope $testReplicationScope | Should Be $true;
            }

            It 'Passes when DNS zone "DynamicUpdate" is correct' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope -DynamicUpdate $testDynamicUpdate | Should Be $true;
            }

            It 'Passes when DNS zone "ReplicationScope" is correct' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope | Should Be $true;
            }

            It 'Passes when DNS zone "DirectoryPartitionName" is correct' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope -DirectoryPartitionName $testDirectoryPartitionName | Should Be $true;
            }

            It 'Fails when DNS zone exists and "Ensure" = "Absent"' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Absent -ReplicationScope $testReplicationScope | Should Be $false;
            }

            It 'Fails when DNS zone does not exist and "Ensure" = "Present"' {
                Mock -CommandName Get-TargetResource -MockWith { }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope | Should Be $false;
            }

            It 'Fails when DNS zone "DynamicUpdate" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope -DynamicUpdate 'NonsecureAndSecure' | Should Be $false;
            }

            It 'Fails when DNS zone "ReplicationScope" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope 'Forest' | Should Be $false;
            }

            It 'Fails when DNS zone "DirectoryPartitionName" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Test-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope -DirectoryPartitionName 'IncorrectDirectoryPartitionName' | Should Be $false;
            }

        } #end context Validates Test-TargetResource Method

        Context 'Validates Set-TargetResource Method' {

            It 'Calls "Add-DnsServerPrimaryZone" when DNS zone does not exist and "Ensure" = "Present"' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakeAbsentTargetResource }
                Mock -CommandName Add-DnsServerPrimaryZone -ParameterFilter { $Name -eq $testZoneName } -MockWith { }
                Set-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope -DynamicUpdate $testDynamicUpdate;
                Assert-MockCalled -CommandName Add-DnsServerPrimaryZone -ParameterFilter { $Name -eq $testZoneName } -Scope It;
            }

            It 'Calls "Remove-DnsServerZone" when DNS zone does exist and "Ensure" = "Absent"' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Mock -CommandName Remove-DnsServerZone -MockWith { }
                Set-TargetResource @testParams -Ensure Absent -ReplicationScope $testReplicationScope -DynamicUpdate $testDynamicUpdate;
                Assert-MockCalled -CommandName Remove-DnsServerZone -Scope It;
            }

            It 'Calls "Set-DnsServerPrimaryZone" when DNS zone "DynamicUpdate" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Mock -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $DynamicUpdate -eq 'NonsecureAndSecure' } -MockWith { }
                Set-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope -DynamicUpdate 'NonsecureAndSecure';
                Assert-MockCalled -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $DynamicUpdate -eq 'NonsecureAndSecure' } -Scope It;
            }

            It 'Calls "Set-DnsServerPrimaryZone" when DNS zone "ReplicationScope" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Mock -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $ReplicationScope -eq 'Forest' } -MockWith { }
                Set-TargetResource @testParams -Ensure Present -ReplicationScope 'Forest';
                Assert-MockCalled -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $ReplicationScope -eq 'Forest' } -Scope It;
            }

            It 'Calls "Set-DnsServerPrimaryZone" when DNS zone "DirectoryPartitionName" is incorrect' {
                Mock -CommandName Get-TargetResource -MockWith { return $fakePresentTargetResource; }
                Mock -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $DirectoryPartitionName -eq 'IncorrectDirectoryPartitionName' } -MockWith { }
                Set-TargetResource @testParams -Ensure Present -ReplicationScope $testReplicationScope -DirectoryPartitionName 'IncorrectDirectoryPartitionName';
                Assert-MockCalled -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $DirectoryPartitionName -eq 'IncorrectDirectoryPartitionName' } -Scope It;
            }

        } #end context Validates Set-TargetResource Method

    }
}
