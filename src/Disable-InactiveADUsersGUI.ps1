function Disable-InactiveADUsersGUI{
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.AutoSize = $true
    $form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $form.Text = "ATG AD Onboarding"

    $MainFlow = New-Object System.Windows.Forms.FlowLayoutPanel
    $MainFlow.Dock = 'Fill'
    $MainFlow.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown

    $CompanyOUBox = New-LabelTextButtonPanel `
        -LabelText "Company OU:" `
        -ButtonText "Select OU" `
        -OnButtonClick {Select-OU}
    
    $form.Controls.Add($OUBox)
    $form.ShowDialog()
}

function New-LabelTextButtonPanel {
    param(
        [string]$LabelText,
        [string]$ButtonText,
        [scriptblock]$OnButtonClick
    )

    $panel = New-Object System.Windows.Forms.TableLayoutPanel
    $panel.RowCount = 1
    $panel.ColumnCount = 3
    $panel.AutoSize = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $LabelText
    $lbl.AutoSize = $true
    $panel.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Width = 180
    $txt.Enabled = $false
    $panel.Controls.Add($txt)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $ButtonText
    $panel.Controls.Add($btn)

    if ($OnButtonClick) {
        $txt.Text = $btn.Add_Click($OnButtonClick)
    }

    return $panel
}