# Install image processing libraries
Set-Location "image-processing"
python -m pip install -r requirements.txt -t python/
New-Item -ItemType Directory -Path "../build" -Force
Compress-Archive -Path python -DestinationPath "../build/image-layer.zip" -Force
Write-Host "Image layer built: layers/build/image-layer.zip"
Set-Location ".."