const std = @import("std");
const libusb = @import("libusb");

pub fn main() !void {
    try libusb.init(.{ .log_level = .info });
    defer libusb.deinit();

    var my_device: *libusb.Device = undefined;
    var root_hubs: [10]*libusb.Device = undefined;
    var root_hubs_len: usize = 0;
    {
        const devices = try libusb.getDeviceList(); // +1 refcount
        defer libusb.freeDeviceList(devices, true); // -1 refcount

        std.mem.sortUnstable(*libusb.Device, devices, {}, libusb.Device.lessThan);

        for (devices) |device| {
            my_device = device.ref(); // +1 refcount

            const bus_num = device.getBusNumber();
            const port_num = device.getPortNumber();

            // const ports_arr, const ports_len = device.getPortNumbers() catch unreachable;
            // const ports = ports_arr[0..ports_len];
            var buffer: [7]u8 = undefined;
            const ports = try device.getPortNumbersSlice(&buffer);

            const speed = device.getSpeed();

            std.debug.print("Bus {}, Ports: {any}, Port: {}, speed: {f}\n", .{ bus_num, ports, port_num, speed });

            if (ports.len == 0) {
                root_hubs[root_hubs_len] = device.ref();
                root_hubs_len += 1;
            }

            my_device.unref(); // -1 refcount
        }
    }

    for (root_hubs[0..root_hubs_len]) |root_hub| {
        const bus_num = root_hub.getBusNumber();
        const ports_arr, const ports_len = root_hub.getPortNumbers() catch unreachable;
        const ports = ports_arr[0..ports_len];

        std.debug.print("Bus {}, Ports: {any}\n", .{ bus_num, ports });

        root_hub.unref();
    }

    // var config_desc = try my_device.getActiveConfigDescriptor();
    // defer config_desc.deinit();

    // const interface_desc = config_desc.interfacesSlice()[0].toSlice()[0];
    // const write_endpoint = interface_desc.endpointsSlice()[0];

    // std.debug.assert(write_endpoint.bmAttributes.transfer_type == .bulk);
    // std.debug.assert(write_endpoint.bEndpointAddress.direction == .output);

    // const device_handle = try my_device.open();
    // defer device_handle.close();
    // defer device_handle.reset() catch {};

    // const my_interface = try device_handle.claimInterface(interface_desc.bInterfaceNumber);
    // defer my_interface.release();

    // const w = my_interface.writable(write_endpoint.bEndpointAddress, 0);
    // try std.fmt.format(w.writer(), "Hello World\n", .{});
}
