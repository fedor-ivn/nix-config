# Shared Syncthing device/folder declarations, so hosts that join the mesh
# don't each redeclare the same device IDs and folder shape.
{ secrets }:
{
  devices = {
    fedorivns-iphone.id = secrets.syncthingDevices.fedorivns-iphone;
    fedorivns-mbp.id = secrets.syncthingDevices.fedorivns-mbp;
    macbook-DLQX9KQ54V.id = secrets.syncthingDevices.macbook-DLQX9KQ54V;
  };

  mkDocumentsFolder = { path, devices }: {
    id = "default";
    inherit path devices;
  };
}
