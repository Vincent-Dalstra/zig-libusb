const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const libusb = @import("libusb");

pub fn main() !void {
    // memory
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const alloc = arena.allocator();
    var debugAllocator: std.heap.DebugAllocator(.{}) = .init;
    defer assert(debugAllocator.deinit() == .ok); // Check for leaks
    const alloc: Allocator = debugAllocator.allocator();

    // libusb
    try libusb.init(.{ .log_level = .info });
    defer libusb.deinit();

    var my_device: *libusb.Device = undefined;
    var root_hubs: [10]*libusb.Device = undefined;
    var root_hubs_len: usize = 0;
    {
        const devices = try libusb.getDeviceList(); // +1 refcount
        defer libusb.freeDeviceList(devices, true); // -1 refcount

        // Put them in order of Bus and Ports
        std.mem.sortUnstable(*libusb.Device, devices, {}, libusb.Device.lessThan);

        for (devices) |device| {
            my_device = device.ref(); // +1 refcount
            defer my_device.unref(); // -1 refcount

            const bus_num = device.getBusNumber();
            const port_num = device.getPortNumber();

            var buffer: [7]u8 = undefined;
            const ports = try device.getPortNumbersSlice(&buffer);
            const address = device.getAddress();
            const speed = device.getSpeed();

            for (0..ports.len) |_| std.debug.print("--", .{});
            std.debug.print("Bus {}, Ports: {any}, Port: {}, address: {}, speed: {f}\n", .{ bus_num, ports, port_num, address, speed });

            const desc = try device.getDescriptor();
            const handle = device.open() catch continue; // +1 refcount when successful
            defer handle.close(); // -1 refcount

            const serial = handle.getStringDescriptorAscii(desc.iSerialNumber, alloc) catch "";
            defer alloc.free(serial);

            for (0..ports.len) |_| std.debug.print("  ", .{});
            std.debug.print("length: {}, serial: {s}\n", .{ desc.bLength, serial });

            if (ports.len == 0) {
                root_hubs[root_hubs_len] = device.ref();
                root_hubs_len += 1;
            }
        }
    }

    for (root_hubs[0..root_hubs_len]) |root_hub| {
        const bus_num = root_hub.getBusNumber();
        const speed = root_hub.getSpeed();

        std.debug.print("Root hub {}, Speed: {f}\n", .{ bus_num, speed });

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
