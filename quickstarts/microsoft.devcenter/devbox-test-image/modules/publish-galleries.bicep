param imageName string
param location string = resourceGroup().location
param imageGalleries array = []

// Get resource IDs for Compute Gallery VM Image Defintions
module modules 'publish-gallery.bicep' = [for (imageGalleryItem, i) in imageGalleries: {
  name: 'publish-gallery-${i}-${uniqueString(deployment().name)}'
  scope: resourceGroup(imageGalleryItem.gallerySubscriptionId, imageGalleryItem.galleryResourceGroup)
  params: {
    galleryName: imageGalleryItem.galleryName
    imageName: imageName
    location: location
  }
}]

output galleryIds array = [for i in range(0, length(imageGalleries)): {
  Id: modules[i].outputs.computeGalleryId
}]
