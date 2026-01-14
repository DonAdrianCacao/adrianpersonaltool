#Requires -Version 5.1

<#
.SYNOPSIS
    AdrianTool - Adrian's Remote App Launcher & PC Tweaking Tool
.DESCRIPTION
    A GUI application launcher for downloading/installing various applications with PC tweaking features
    Run with: iex "& { $(irm https://raw.githubusercontent.com/DonAdrianCacao/adrianpersonaltool/main/adriantool.ps1) }"
.NOTES
    Author: Adrian (DonAdrianCacao)
    Version: 1.1
#>

# Set execution policy for this session (required for remote execution)
if ($ExecutionContext.SessionState.LanguageMode -ne "FullLanguage") {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Apps configuration
$apps = @{
    "Browsers" = @(
        @{Name="Chrome"; URL="https://www.google.com/chrome/"},
        @{Name="Brave"; URL="https://brave.com/download/"}
    )
    "Gaming" = @(
        @{Name="NIKKE"; URL="https://nikke-en.com/"},
        @{Name="HoYoVerse"; URL="https://www.hoyoverse.com/en-us/"},
        @{Name="Wuthering Waves"; URL="https://wutheringwaves.kurogames.com/en/"},
        @{Name="Steam"; URL="https://store.steampowered.com/about/"},
        @{Name="Epic Games"; URL="https://store.epicgames.com/"}
    )
    "Apps" = @(
        @{Name="Lightshot"; URL="https://app.prntscr.com/en/download.html"},
        @{Name="Geek Uninstaller"; URL="https://geekuninstaller.com/download"},
        @{Name="ExitLag"; URL="https://www.exitlag.com/"},
        @{Name="Discord"; URL="https://discord.com/download"},
        @{Name="Avidemux"; URL="https://sourceforge.net/projects/avidemux/files/avidemux/"}
    )
    "Programming" = @(
        @{Name="VS Code"; URL="https://code.visualstudio.com/download"},
        @{Name="Cursor"; URL="https://cursor.sh/"},
        @{Name="Python"; URL="https://www.python.org/downloads/"},
        @{Name="Node.js"; URL="https://nodejs.org/"}
    )
    "Tools" = @(
        @{Name="MSI Afterburner"; URL="https://www.msi.com/Landing/afterburner/graphics-cards"},
        @{Name="NVIDIA App"; URL="https://www.nvidia.com/en-us/software/nvidia-app/"},
        @{Name="HWiNFO"; URL="https://www.hwinfo.com/download/"},
        @{Name="GPU-Z"; URL="https://www.techpowerup.com/gpuz/"},
        @{Name="CrystalDiskInfo"; URL="https://crystalmark.info/en/software/crystaldiskinfo/"}
    )
}

# Global variables
$script:selectedItems = New-Object System.Collections.ArrayList
$script:selectMultiple = $false
$script:mainPanel = $null
$script:categoryButtons = @{}
$script:currentView = "Software"
$script:softwareBtn = $null
$script:tweaksBtn = $null

# Color scheme
$colors = @{
    Primary = [System.Drawing.Color]::FromArgb(255, 20, 147)
    PrimaryDark = [System.Drawing.Color]::FromArgb(180, 14, 103)
    Background = [System.Drawing.Color]::FromArgb(5, 5, 5)
    Surface = [System.Drawing.Color]::FromArgb(12, 12, 12)
    SurfaceLight = [System.Drawing.Color]::FromArgb(18, 18, 18)
    Text = [System.Drawing.Color]::White
    TextSecondary = [System.Drawing.Color]::FromArgb(140, 140, 140)
    Border = [System.Drawing.Color]::FromArgb(30, 30, 30)
    Hover = [System.Drawing.Color]::FromArgb(25, 25, 25)
    Selected = [System.Drawing.Color]::FromArgb(255, 20, 147)
    Success = [System.Drawing.Color]::FromArgb(46, 204, 113)
    Warning = [System.Drawing.Color]::FromArgb(241, 196, 15)
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AdrianTool - App Launcher & PC Tweaking"
$form.Size = New-Object System.Drawing.Size(1080, 780)
$form.StartPosition = "CenterScreen"
$form.BackColor = $colors.Background
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false

# Top bar
$topBar = New-Object System.Windows.Forms.Panel
$topBar.Location = New-Object System.Drawing.Point(0, 0)
$topBar.Size = New-Object System.Drawing.Size(1080, 45)
$topBar.BackColor = $colors.Surface
$form.Controls.Add($topBar)

# Title
$title = New-Object System.Windows.Forms.Label
$title.Text = "ADRIANTOOL"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $colors.Primary
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 12)
$topBar.Controls.Add($title)

# View buttons
$softwareBtn = New-Object System.Windows.Forms.Button
$softwareBtn.Text = "SOFTWARE"
$softwareBtn.Size = New-Object System.Drawing.Size(100, 30)
$softwareBtn.Location = New-Object System.Drawing.Point(180, 8)
$softwareBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$softwareBtn.BackColor = $colors.Primary
$softwareBtn.ForeColor = $colors.Text
$softwareBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$softwareBtn.FlatAppearance.BorderSize = 0
$softwareBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$softwareBtn.Add_Click({
    if ($script:currentView -ne "Software") {
        $script:currentView = "Software"
        Update-ViewButtons
        Load-Software
    }
})
$topBar.Controls.Add($softwareBtn)
$script:softwareBtn = $softwareBtn

$tweaksBtn = New-Object System.Windows.Forms.Button
$tweaksBtn.Text = "PC TWEAKS"
$tweaksBtn.Size = New-Object System.Drawing.Size(100, 30)
$tweaksBtn.Location = New-Object System.Drawing.Point(290, 8)
$tweaksBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$tweaksBtn.BackColor = $colors.SurfaceLight
$tweaksBtn.ForeColor = $colors.TextSecondary
$tweaksBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tweaksBtn.FlatAppearance.BorderSize = 1
$tweaksBtn.FlatAppearance.BorderColor = $colors.Border
$tweaksBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$tweaksBtn.Add_Click({
    if ($script:currentView -ne "Tweaks") {
        $script:currentView = "Tweaks"
        Update-ViewButtons
        Load-PC-Tweaks
    }
})
$topBar.Controls.Add($tweaksBtn)
$script:tweaksBtn = $tweaksBtn

# Launch button
$launchBtn = New-Object System.Windows.Forms.Button
$launchBtn.Text = "LAUNCH (0)"
$launchBtn.Size = New-Object System.Drawing.Size(110, 30)
$launchBtn.Location = New-Object System.Drawing.Point(950, 8)
$launchBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$launchBtn.BackColor = $colors.Primary
$launchBtn.ForeColor = $colors.Text
$launchBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$launchBtn.FlatAppearance.BorderSize = 0
$launchBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$launchBtn.Add_Click({
    if ($script:selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select apps to launch", "No Selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    foreach ($url in $script:selectedItems) {
        try {
            Start-Process $url
            Start-Sleep -Milliseconds 500
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to open: $url", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})
$topBar.Controls.Add($launchBtn)

# Mode toggle
$modeBtn = New-Object System.Windows.Forms.Button
$modeBtn.Text = "SINGLE"
$modeBtn.Size = New-Object System.Drawing.Size(90, 30)
$modeBtn.Location = New-Object System.Drawing.Point(840, 8)
$modeBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$modeBtn.BackColor = $colors.SurfaceLight
$modeBtn.ForeColor = $colors.Text
$modeBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$modeBtn.FlatAppearance.BorderSize = 1
$modeBtn.FlatAppearance.BorderColor = $colors.Border
$modeBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$modeBtn.Add_Click({
    $script:selectMultiple = !$script:selectMultiple
    $script:selectedItems.Clear()
    Update-LaunchButton
    Clear-AppSelection

    if ($script:selectMultiple) {
        $this.Text = "MULTI"
        $this.BackColor = $colors.Primary
        $this.FlatAppearance.BorderColor = $colors.Primary
    } else {
        $this.Text = "SINGLE"
        $this.BackColor = $colors.SurfaceLight
        $this.FlatAppearance.BorderColor = $colors.Border
    }
})
$topBar.Controls.Add($modeBtn)

# Main panel
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Location = New-Object System.Drawing.Point(0, 45)
$mainPanel.Size = New-Object System.Drawing.Size(1080, 735)
$mainPanel.AutoScroll = $true
$mainPanel.BackColor = $colors.Background
$form.Controls.Add($mainPanel)
$script:mainPanel = $mainPanel

# Functions
function Update-LaunchButton {
    $launchBtn.Text = "LAUNCH ($($script:selectedItems.Count))"
}

function Update-ViewButtons {
    if ($script:currentView -eq "Software") {
        $script:softwareBtn.BackColor = $colors.Primary
        $script:softwareBtn.ForeColor = $colors.Text
        $script:softwareBtn.FlatAppearance.BorderSize = 0
        $script:tweaksBtn.BackColor = $colors.SurfaceLight
        $script:tweaksBtn.ForeColor = $colors.TextSecondary
        $script:tweaksBtn.FlatAppearance.BorderSize = 1
        $script:tweaksBtn.FlatAppearance.BorderColor = $colors.Border
    } else {
        $script:tweaksBtn.BackColor = $colors.Primary
        $script:tweaksBtn.ForeColor = $colors.Text
        $script:tweaksBtn.FlatAppearance.BorderSize = 0
        $script:softwareBtn.BackColor = $colors.SurfaceLight
        $script:softwareBtn.ForeColor = $colors.TextSecondary
        $script:softwareBtn.FlatAppearance.BorderSize = 1
        $script:softwareBtn.FlatAppearance.BorderColor = $colors.Border
    }
}

function Clear-AppSelection {
    foreach ($ctrl in $script:mainPanel.Controls) {
        if ($ctrl -is [System.Windows.Forms.Panel]) {
            foreach ($innerCtrl in $ctrl.Controls) {
                if ($innerCtrl -is [System.Windows.Forms.Panel]) {
                    foreach ($btn in $innerCtrl.Controls) {
                        if ($btn -is [System.Windows.Forms.Button] -and $btn.Tag -and $btn.Tag -ne "SELECT_ALL") {
                            $btn.BackColor = $colors.Surface
                            $btn.FlatAppearance.BorderColor = $colors.Border
                            $btn.ForeColor = $colors.Text
                        }
                    }
                }
            }
        }
    }
}

function Select-CategoryApps {
    param($category, $selectAllBtn)

    if (-not $script:selectMultiple) {
        [System.Windows.Forms.MessageBox]::Show("Enable MULTI mode to select categories", "Single Mode Active", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    $categoryApps = $apps[$category]
    $allSelected = $true

    foreach ($app in $categoryApps) {
        if (-not $script:selectedItems.Contains($app.URL)) {
            $allSelected = $false
            break
        }
    }

    if ($allSelected) {
        # Deselect all
        foreach ($app in $categoryApps) {
            $script:selectedItems.Remove($app.URL)
        }
        $selectAllBtn.Text = "[+]"
        $selectAllBtn.BackColor = $colors.SurfaceLight
    } else {
        # Select all
        foreach ($app in $categoryApps) {
            if (-not $script:selectedItems.Contains($app.URL)) {
                [void]$script:selectedItems.Add($app.URL)
            }
        }
        $selectAllBtn.Text = "[-]"
        $selectAllBtn.BackColor = $colors.Primary
    }

    Update-LaunchButton
    Update-CategoryButtons
}

function Update-CategoryButtons {
    foreach ($ctrl in $script:mainPanel.Controls) {
        if ($ctrl -is [System.Windows.Forms.Panel]) {
            foreach ($innerCtrl in $ctrl.Controls) {
                if ($innerCtrl -is [System.Windows.Forms.Panel]) {
                    foreach ($btn in $innerCtrl.Controls) {
                        if ($btn -is [System.Windows.Forms.Button]) {
                            if ($btn.Tag -and $btn.Tag -ne "SELECT_ALL") {
                                # Update app buttons
                                if ($script:selectedItems.Contains($btn.Tag)) {
                                    $btn.BackColor = $colors.Selected
                                    $btn.FlatAppearance.BorderColor = $colors.Primary
                                } else {
                                    $btn.BackColor = $colors.Surface
                                    $btn.FlatAppearance.BorderColor = $colors.Border
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

function Create-AppButton {
    param($app)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $app.Name
    $button.Size = New-Object System.Drawing.Size(180, 30)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.BackColor = $colors.Surface
    $button.ForeColor = $colors.Text
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $button.FlatAppearance.BorderColor = $colors.Border
    $button.FlatAppearance.BorderSize = 1
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Tag = $app.URL
    $button.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $button.Padding = New-Object System.Windows.Forms.Padding(8, 0, 0, 0)

    $button.Add_MouseEnter({
        if ($script:selectedItems -notcontains $this.Tag) {
            $this.BackColor = $colors.Hover
        }
    })

    $button.Add_MouseLeave({
        if ($script:selectedItems -notcontains $this.Tag) {
            $this.BackColor = $colors.Surface
        }
    })

    $button.Add_Click({
        if ($script:selectMultiple) {
            $url = $this.Tag
            if ($script:selectedItems.Contains($url)) {
                $script:selectedItems.Remove($url)
                $this.BackColor = $colors.Surface
                $this.FlatAppearance.BorderColor = $colors.Border
            } else {
                [void]$script:selectedItems.Add($url)
                $this.BackColor = $colors.Selected
                $this.FlatAppearance.BorderColor = $colors.Primary
            }
            Update-LaunchButton
            Update-CategoryButtons
        } else {
            try {
                Start-Process $this.Tag
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to open: $($this.Tag)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    })

    return $button
}

function Create-ToggleButton {
    param($text, $yPos)

    $toggleBtn = New-Object System.Windows.Forms.Button
    $toggleBtn.Text = "OFF"
    $toggleBtn.Size = New-Object System.Drawing.Size(60, 35)
    $toggleBtn.Location = New-Object System.Drawing.Point(450, $yPos)
    $toggleBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $toggleBtn.BackColor = $colors.SurfaceLight
    $toggleBtn.ForeColor = $colors.TextSecondary
    $toggleBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $toggleBtn.FlatAppearance.BorderSize = 1
    $toggleBtn.FlatAppearance.BorderColor = $colors.Border
    $toggleBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $toggleBtn.Tag = $false

    $toggleBtn.Add_Click({
        $this.Tag = !$this.Tag
        if ($this.Tag) {
            $this.Text = "ON"
            $this.BackColor = $colors.Success
            $this.ForeColor = $colors.Text
            $this.FlatAppearance.BorderColor = $colors.Success
        } else {
            $this.Text = "OFF"
            $this.BackColor = $colors.SurfaceLight
            $this.ForeColor = $colors.TextSecondary
            $this.FlatAppearance.BorderColor = $colors.Border
        }
    })

    return $toggleBtn
}

function Load-Software {
    $script:mainPanel.Controls.Clear()

    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point(20, 20)
    $container.Size = New-Object System.Drawing.Size(1040, 700)
    $container.BackColor = $colors.Background
    $script:mainPanel.Controls.Add($container)

    $xPos = 0

    foreach ($category in $apps.Keys) {
        $categoryApps = $apps[$category]
        if ($categoryApps.Count -eq 0) { continue }

        # Category panel
        $categoryPanel = New-Object System.Windows.Forms.Panel
        $categoryPanel.Location = New-Object System.Drawing.Point($xPos, 0)
        $categoryPanel.Size = New-Object System.Drawing.Size(190, 480)
        $categoryPanel.BackColor = $colors.Background
        $container.Controls.Add($categoryPanel)

        # Header
        $headerPanel = New-Object System.Windows.Forms.Panel
        $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
        $headerPanel.Size = New-Object System.Drawing.Size(180, 32)
        $headerPanel.BackColor = $colors.Surface
        $categoryPanel.Controls.Add($headerPanel)

        # Category title
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $category.ToUpper()
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $titleLabel.ForeColor = $colors.Primary
        $titleLabel.AutoSize = $false
        $titleLabel.Size = New-Object System.Drawing.Size(130, 32)
        $titleLabel.Location = New-Object System.Drawing.Point(8, 0)
        $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $headerPanel.Controls.Add($titleLabel)

        # Select all button
        $selectAllBtn = New-Object System.Windows.Forms.Button
        $selectAllBtn.Text = "[+]"
        $selectAllBtn.Size = New-Object System.Drawing.Size(35, 24)
        $selectAllBtn.Location = New-Object System.Drawing.Point(140, 4)
        $selectAllBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $selectAllBtn.BackColor = $colors.SurfaceLight
        $selectAllBtn.ForeColor = $colors.Text
        $selectAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $selectAllBtn.FlatAppearance.BorderSize = 1
        $selectAllBtn.FlatAppearance.BorderColor = $colors.Border
        $selectAllBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
        $selectAllBtn.Tag = "SELECT_ALL"
        $selectAllBtn.Add_Click({
            Select-CategoryApps -category $category -selectAllBtn $this
        }.GetNewClosure())
        $headerPanel.Controls.Add($selectAllBtn)

        # Border line
        $border = New-Object System.Windows.Forms.Panel
        $border.Location = New-Object System.Drawing.Point(0, 32)
        $border.Size = New-Object System.Drawing.Size(180, 1)
        $border.BackColor = $colors.Primary
        $categoryPanel.Controls.Add($border)

        # Apps panel
        $appsPanel = New-Object System.Windows.Forms.Panel
        $appsPanel.Location = New-Object System.Drawing.Point(0, 38)
        $appsPanel.Size = New-Object System.Drawing.Size(190, 440)
        $appsPanel.BackColor = $colors.Background
        $categoryPanel.Controls.Add($appsPanel)

        # Add apps
        $yPos = 0
        foreach ($app in $categoryApps) {
            $button = Create-AppButton -app $app
            $button.Location = New-Object System.Drawing.Point(0, $yPos)
            $appsPanel.Controls.Add($button)
            $yPos += 35
        }

        $xPos += 200
    }
}

function Load-PC-Tweaks {
    $script:mainPanel.Controls.Clear()

    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point(10, 10)
    $container.Size = New-Object System.Drawing.Size(1030, 710)
    $container.BackColor = $colors.Background
    $script:mainPanel.Controls.Add($container)

    # PC TWEAKING SECTION
    $tweakingPanel = New-Object System.Windows.Forms.Panel
    $tweakingPanel.Location = New-Object System.Drawing.Point(0, 0)
    $tweakingPanel.Size = New-Object System.Drawing.Size(1030, 710)
    $tweakingPanel.BackColor = $colors.Background
    $container.Controls.Add($tweakingPanel)

    # Tweaking header
    $tweakHeaderPanel = New-Object System.Windows.Forms.Panel
    $tweakHeaderPanel.Location = New-Object System.Drawing.Point(0, 0)
    $tweakHeaderPanel.Size = New-Object System.Drawing.Size(1030, 50)
    $tweakHeaderPanel.BackColor = $colors.Surface
    $tweakingPanel.Controls.Add($tweakHeaderPanel)

    $tweakTitle = New-Object System.Windows.Forms.Label
    $tweakTitle.Text = "PC TWEAKING TOOLS"
    $tweakTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $tweakTitle.ForeColor = $colors.Primary
    $tweakTitle.AutoSize = $true
    $tweakTitle.Location = New-Object System.Drawing.Point(15, 12)
    $tweakHeaderPanel.Controls.Add($tweakTitle)

    # Border under header
    $tweakBorder = New-Object System.Windows.Forms.Panel
    $tweakBorder.Location = New-Object System.Drawing.Point(0, 50)
    $tweakBorder.Size = New-Object System.Drawing.Size(1030, 2)
    $tweakBorder.BackColor = $colors.Primary
    $tweakingPanel.Controls.Add($tweakBorder)

    # Tweaking content area
    $tweakContent = New-Object System.Windows.Forms.Panel
    $tweakContent.Location = New-Object System.Drawing.Point(0, 60)
    $tweakContent.Size = New-Object System.Drawing.Size(1030, 640)
    $tweakContent.BackColor = $colors.Background
    $tweakingPanel.Controls.Add($tweakContent)

    # Left column
    $leftColumn = New-Object System.Windows.Forms.Panel
    $leftColumn.Location = New-Object System.Drawing.Point(15, 20)
    $leftColumn.Size = New-Object System.Drawing.Size(500, 600)
    $leftColumn.BackColor = $colors.Background
    $tweakContent.Controls.Add($leftColumn)

    $tweakSettings = @(
        "Create Restore Point",
        "Enable Game Mode",
        "Enable Hardware-accelerated GPU",
        "Disable Telemetry",
        "Set Classic Right-Click Menu",
        "Prefer IPv4 over IPv6"
    )

    $yPosition = 0
    foreach ($setting in $tweakSettings) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $setting
        $label.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $label.ForeColor = $colors.Text
        $label.AutoSize = $false
        $label.Size = New-Object System.Drawing.Size(380, 35)
        $label.Location = New-Object System.Drawing.Point(0, $yPosition)
        $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $leftColumn.Controls.Add($label)

        $toggleBtn = Create-ToggleButton -text $setting -yPos $yPosition
        $toggleBtn.Location = New-Object System.Drawing.Point(390, $yPosition)
        $leftColumn.Controls.Add($toggleBtn)

        $yPosition += 45
    }

    # Right column
    $rightColumn = New-Object System.Windows.Forms.Panel
    $rightColumn.Location = New-Object System.Drawing.Point(530, 20)
    $rightColumn.Size = New-Object System.Drawing.Size(480, 600)
    $rightColumn.BackColor = $colors.Background
    $tweakContent.Controls.Add($rightColumn)

    # Dark Theme Toggle
    $darkThemeLabel = New-Object System.Windows.Forms.Label
    $darkThemeLabel.Text = "Dark Theme"
    $darkThemeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $darkThemeLabel.ForeColor = $colors.Text
    $darkThemeLabel.AutoSize = $false
    $darkThemeLabel.Size = New-Object System.Drawing.Size(340, 35)
    $darkThemeLabel.Location = New-Object System.Drawing.Point(0, 0)
    $darkThemeLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $rightColumn.Controls.Add($darkThemeLabel)

    $darkThemeToggle = New-Object System.Windows.Forms.Button
    $darkThemeToggle.Text = "OFF"
    $darkThemeToggle.Size = New-Object System.Drawing.Size(80, 30)
    $darkThemeToggle.Location = New-Object System.Drawing.Point(350, 3)
    $darkThemeToggle.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $darkThemeToggle.BackColor = $colors.SurfaceLight
    $darkThemeToggle.ForeColor = $colors.TextSecondary
    $darkThemeToggle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $darkThemeToggle.FlatAppearance.BorderSize = 1
    $darkThemeToggle.FlatAppearance.BorderColor = $colors.Border
    $darkThemeToggle.Cursor = [System.Windows.Forms.Cursors]::Hand
    $darkThemeToggle.Tag = $false
    $darkThemeToggle.Add_Click({
        $this.Tag = !$this.Tag
        if ($this.Tag) {
            $this.Text = "ON"
            $this.BackColor = $colors.Success
            $this.ForeColor = $colors.Text
            $this.FlatAppearance.BorderColor = $colors.Success
        } else {
            $this.Text = "OFF"
            $this.BackColor = $colors.SurfaceLight
            $this.ForeColor = $colors.TextSecondary
            $this.FlatAppearance.BorderColor = $colors.Border
        }
    })
    $rightColumn.Controls.Add($darkThemeToggle)

    # DNS Settings
    $dnsLabel = New-Object System.Windows.Forms.Label
    $dnsLabel.Text = "DNS Settings"
    $dnsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $dnsLabel.ForeColor = $colors.Text
    $dnsLabel.AutoSize = $false
    $dnsLabel.Size = New-Object System.Drawing.Size(340, 35)
    $dnsLabel.Location = New-Object System.Drawing.Point(0, 50)
    $dnsLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $rightColumn.Controls.Add($dnsLabel)

    $dnsDropdown = New-Object System.Windows.Forms.ComboBox
    $dnsDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $dnsDropdown.Size = New-Object System.Drawing.Size(140, 30)
    $dnsDropdown.Location = New-Object System.Drawing.Point(350, 53)
    $dnsDropdown.BackColor = $colors.Surface
    $dnsDropdown.ForeColor = $colors.Text
    $dnsDropdown.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $dnsDropdown.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $dnsDropdown.Items.AddRange(@("Default", "Google DNS"))
    $dnsDropdown.SelectedIndex = 0
    $rightColumn.Controls.Add($dnsDropdown)

}

# Load the application
try {
    Load-Software
    [void]$form.ShowDialog()
} catch {
    Write-Warning "An error occurred: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show("An error occurred while loading the application: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
} finally {
    $form.Dispose()
}