function Select-OU {
    Import-Module ActiveDirectory -ErrorAction Break
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form

    $table = New-Object System.Windows.Forms.TableLayoutPanel
    $table.Dock = 'Fill'

    $treeView = New-Object System.Windows.Forms.TreeView
    $treeView.AutoSize = $true
    $treeView.Dock = 'Fill'
    $domainRoot = Get-ADDomain
    # Recursive Function to populate Tree
    function Add-OUsToTree {
        param(
            [string]$baseDN,
            [System.Windows.Forms.TreeNode]$parentNode
        )
        $childOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $baseDN -SearchScope OneLevel

        foreach ($ou in $childOUs) {
            $node = New-Object System.Windows.Forms.TreeNode
            $node.Text = $ou.Name
            $node.Tag = $ou.DistinguishedName
            [void]$parentNode.Nodes.Add($node) # TreeNodeCollection.Add() returns an int, clean that up so it doesn't spill into function output
            Add-OUsToTree -baseDN $ou.DistinguishedName -parentNode $node
        }
    }
    $rootNode = New-Object System.Windows.Forms.TreeNode
    $rootNode.Text = $domainRoot.Name
    $rootNode.Tag = $domainRoot.DistinguishedName
    [void]$treeView.Nodes.Add($rootNode)
    Add-OUsToTree $domainRoot.DistinguishedName $rootNode
    $treeView.ExpandAll()
    $table.Controls.Add($treeView)
    
    $bottomPanel = New-Object System.Windows.Forms.FlowLayoutPanel

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.AutoSize = 'True'
    $okButton.Text = 'Select'
    $okButton.Add_Click({
        if ($treeView.SelectedNode.Tag) {
            $form.DialogResult = 'Ok'
            $form.Close()
        }
    })
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.AutoSize = 'True'
    $cancelButton.Text = 'Cancel'
    $form.CancelButton = $cancelButton

    $bottomPanel.Controls.Add($cancelButton)
    $bottomPanel.Controls.Add($okButton)
    $bottomPanel.Dock = 'Bottom'
    $bottomPanel.AutoSize = 'True'
    $bottomPanel.FlowDirection = 'RightToLeft'
    $form.Controls.Add($bottomPanel)

    $form.Controls.add($table)
    $form.ShowDialog() | Out-Null
    return $treeView.SelectedNode.Tag
}