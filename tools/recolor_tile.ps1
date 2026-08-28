param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 100)]
    [double]$HuePercent,

    [ValidateRange(0, 300)]
    [double]$SaturationPercent = 100,

    [ValidateRange(0, 300)]
    [double]$LightnessPercent = 100
)

$magick = Get-Command magick -ErrorAction Stop
$saturationScale = $SaturationPercent / 100.0
$lightnessScale = $LightnessPercent / 100.0

& $magick.Source $InputPath `
    -colorspace HSL `
    -channel R -evaluate set "$HuePercent%" `
    -channel G -evaluate multiply $saturationScale `
    -channel B -evaluate multiply $lightnessScale `
    +channel -colorspace sRGB `
    $OutputPath

if ($LASTEXITCODE -ne 0) {
    throw "ImageMagick failed to recolor $InputPath"
}
