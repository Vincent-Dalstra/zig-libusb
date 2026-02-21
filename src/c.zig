const std = @import("std");
const testing = std.testing;
const root = @import("./root.zig");

pub const translated = @cImport({
    @cInclude("libusb.h");
});

pub const ClassCode = root.ClassCode;
pub const DescriptorType = root.DescriptorType;
pub const BOSType = root.BOSType;
pub const StandardRequest = root.StandardRequest;
pub const SupportedSpeed = root.SupportedSpeed;
pub const DeviceDescriptor = root.DeviceDescriptor;
pub const EndpointDescriptor = root.EndpointDescriptor;
pub const InterfaceAssociationDescriptor = root.InterfaceAssociationDescriptor;
pub const InterfaceAssociationDescriptorArray = root.InterfaceAssociationDescriptorArray;
pub const InterfaceDescriptor = root.InterfaceDescriptor;
pub const Interface = root.Interface;
pub const ConfigDescriptor = root.ConfigDescriptor;
pub const SSEndpointCompanionDescriptor = root.SSEndpointCompanionDescriptor;
pub const BOSDeviceCapabilityDescriptor = root.BOSDeviceCapabilityDescriptor;
pub const BOSDescriptor = root.BOSDescriptor;
pub const USB20ExtensionDescriptor = root.USB20ExtensionDescriptor;
pub const SSUSBDeviceCapabilityDescriptor = root.SSUSBDeviceCapabilityDescriptor;
pub const ContainerIdDescriptor = root.ContainerIdDescriptor;
pub const PlatformDescriptor = root.PlatformDescriptor;
pub const ControlSetup = root.ControlSetup;
pub const Version = root.Version;
pub const Context = root.Context;
pub const Device = root.Device;
pub const DeviceHandle = root.DeviceHandle;
pub const Speed = root.Speed;
pub const ErrorCode = root.ErrorCode;
pub const UsizeOrErrorCode = root.UsizeOrErrorCode;
pub const U32OrErrorCode = root.U32OrErrorCode;
pub const TransferStatus = root.TransferStatus;
pub const ISOPacketDescriptor = root.ISOPacketDescriptor;
pub const Transfer = root.Transfer;
pub const Capability = root.Capability;
pub const LogLevel = root.LogLevel;
pub const LogCBMode = root.LogCBMode;
pub const Pollfd = root.Pollfd;
pub const HotplugCallbackHandle = root.HotplugCallbackHandle;
pub const HotplugEvent = root.HotplugEvent;

pub const LogCallbackFn = fn (?*Context, LogLevel, [*c]const u8) callconv(.c) void;

pub const Option = enum(c_uint) {
    log_level = 0,
    use_usbdk = 1,
    no_device_discovery = 2,
    log_cb = 3,
};

pub const InitOption = extern struct {
    option: Option,
    value: extern union {
        void: void,
        log_level: LogLevel,
        log_cb: *const LogCallbackFn,
    },
};

fn castErrorCode(rc: c_int) ErrorCode {
    return @enumFromInt(rc);
}

fn castU32OrErrorCode(rc: c_int) U32OrErrorCode {
    return @enumFromInt(rc);
}

fn castUsizeOrErrorCode(rc: isize) UsizeOrErrorCode {
    return @enumFromInt(rc);
}

pub fn libusb_init_context(ctx: ?*?*Context, options: ?[*]const InitOption, num_options: c_int) ErrorCode {
    const raw_options: ?[*]const translated.struct_libusb_init_option = if (options) |v| @ptrCast(v) else null;
    const rc = translated.libusb_init_context(@ptrCast(ctx), raw_options, num_options);
    return castErrorCode(rc);
}

pub fn libusb_exit(ctx: ?*Context) void {
    translated.libusb_exit(@ptrCast(ctx));
}

pub fn libusb_get_device_list(ctx: ?*Context, list: *?[*]*Device) UsizeOrErrorCode {
    return castUsizeOrErrorCode(translated.libusb_get_device_list(@ptrCast(ctx), @ptrCast(list)));
}

pub fn libusb_free_device_list(list: [*]*Device, unref_devices: bool) void {
    translated.libusb_free_device_list(@ptrCast(list), @intFromBool(unref_devices));
}

pub fn libusb_ref_device(dev: *Device) *Device {
    return @ptrCast(translated.libusb_ref_device(@ptrCast(dev)));
}

pub fn libusb_unref_device(dev: *Device) void {
    translated.libusb_unref_device(@ptrCast(dev));
}

pub fn libusb_get_device_descriptor(dev: *Device, desc: *DeviceDescriptor) ErrorCode {
    return castErrorCode(translated.libusb_get_device_descriptor(@ptrCast(dev), @ptrCast(desc)));
}

pub fn libusb_get_active_config_descriptor(dev: *Device, config: *?*ConfigDescriptor) ErrorCode {
    return castErrorCode(translated.libusb_get_active_config_descriptor(@ptrCast(dev), @ptrCast(config)));
}

pub fn libusb_free_config_descriptor(config: ?*ConfigDescriptor) void {
    translated.libusb_free_config_descriptor(@ptrCast(config));
}

pub fn libusb_get_string_descriptor_ascii(dev_handle: ?*DeviceHandle, desc_index: u8, data: [*]u8, length: c_int) U32OrErrorCode {
    return castU32OrErrorCode(translated.libusb_get_string_descriptor_ascii(@ptrCast(dev_handle), desc_index, data, length));
}

pub fn libusb_open(dev: *Device, dev_handle: *?*DeviceHandle) ErrorCode {
    return castErrorCode(translated.libusb_open(@ptrCast(dev), @ptrCast(dev_handle)));
}

pub fn libusb_close(dev_handle: *DeviceHandle) void {
    translated.libusb_close(@ptrCast(dev_handle));
}

pub fn libusb_get_bus_number(dev: *Device) u8 {
    return translated.libusb_get_bus_number(@ptrCast(dev));
}

pub fn libusb_get_port_number(dev: *Device) u8 {
    return translated.libusb_get_port_number(@ptrCast(dev));
}

pub fn libusb_get_port_numbers(dev: *Device, port_numbers: [*]u8, port_numbers_len: c_int) U32OrErrorCode {
    return castU32OrErrorCode(translated.libusb_get_port_numbers(@ptrCast(dev), @ptrCast(port_numbers), port_numbers_len));
}

pub fn libusb_get_device_address(dev: *Device) u8 {
    return translated.libusb_get_device_address(@ptrCast(dev));
}

pub fn libusb_get_device_speed(dev: *Device) c_int {
    return translated.libusb_get_device_speed(@ptrCast(dev));
}

pub fn libusb_clear_halt(dev_handle: *DeviceHandle, endpoint: u8) ErrorCode {
    return castErrorCode(translated.libusb_clear_halt(@ptrCast(dev_handle), endpoint));
}

pub fn libusb_reset_device(dev_handle: *DeviceHandle) ErrorCode {
    return castErrorCode(translated.libusb_reset_device(@ptrCast(dev_handle)));
}

pub fn libusb_claim_interface(dev_handle: *DeviceHandle, interface_number: c_int) ErrorCode {
    return castErrorCode(translated.libusb_claim_interface(@ptrCast(dev_handle), interface_number));
}

pub fn libusb_release_interface(dev_handle: *DeviceHandle, interface_number: c_int) ErrorCode {
    return castErrorCode(translated.libusb_release_interface(@ptrCast(dev_handle), interface_number));
}

pub fn libusb_bulk_transfer(
    dev_handle: *DeviceHandle,
    endpoint: u8,
    data: [*]u8,
    length: c_int,
    transferred: *c_int,
    timeout: c_uint,
) ErrorCode {
    return castErrorCode(translated.libusb_bulk_transfer(@ptrCast(dev_handle), endpoint, data, length, transferred, timeout));
}

pub fn libusb_alloc_transfer(iso_packets: c_int) ?*Transfer {
    return @ptrCast(translated.libusb_alloc_transfer(iso_packets));
}

pub fn libusb_free_transfer(transfer: *Transfer) void {
    translated.libusb_free_transfer(@ptrCast(transfer));
}

pub fn libusb_submit_transfer(transfer: *Transfer) ErrorCode {
    return castErrorCode(translated.libusb_submit_transfer(@ptrCast(transfer)));
}

pub fn libusb_cancel_transfer(transfer: *Transfer) ErrorCode {
    return castErrorCode(translated.libusb_cancel_transfer(@ptrCast(transfer)));
}

pub fn libusb_transfer_get_stream_id(transfer: *Transfer) u32 {
    return translated.libusb_transfer_get_stream_id(@ptrCast(transfer));
}

pub fn libusb_transfer_set_stream_id(transfer: *Transfer, stream_id: u32) void {
    translated.libusb_transfer_set_stream_id(@ptrCast(transfer), stream_id);
}

pub fn libusb_kernel_driver_active(dev_handle: *DeviceHandle, interface_number: c_int) U32OrErrorCode {
    return castU32OrErrorCode(translated.libusb_kernel_driver_active(@ptrCast(dev_handle), interface_number));
}

pub fn libusb_detach_kernel_driver(dev_handle: *DeviceHandle, interface_number: c_int) ErrorCode {
    return castErrorCode(translated.libusb_detach_kernel_driver(@ptrCast(dev_handle), interface_number));
}

pub fn libusb_attach_kernel_driver(dev_handle: *DeviceHandle, interface_number: c_int) ErrorCode {
    return castErrorCode(translated.libusb_attach_kernel_driver(@ptrCast(dev_handle), interface_number));
}

pub fn libusb_set_auto_detach_kernel_driver(dev_handle: *DeviceHandle, enable: bool) ErrorCode {
    return castErrorCode(translated.libusb_set_auto_detach_kernel_driver(@ptrCast(dev_handle), @intFromBool(enable)));
}

pub fn libusb_interrupt_transfer(
    dev_handle: *DeviceHandle,
    endpoint: u8,
    data: [*]u8,
    length: c_int,
    transferred: *c_int,
    timeout: c_uint,
) ErrorCode {
    return castErrorCode(translated.libusb_interrupt_transfer(@ptrCast(dev_handle), endpoint, data, length, transferred, timeout));
}

pub fn libusb_get_max_alt_packet_size(
    dev: *Device,
    interface_number: c_int,
    alternate_setting: c_int,
    endpoint: u8,
) U32OrErrorCode {
    return castU32OrErrorCode(translated.libusb_get_max_alt_packet_size(
        @ptrCast(dev),
        interface_number,
        alternate_setting,
        endpoint,
    ));
}

test "init context basic" {
    var ctx: ?*Context = null;
    try libusb_init_context(&ctx, null, 0).result();
    try testing.expect(ctx != null);
    defer libusb_exit(ctx);
}

test "init context log level" {
    var ctx: ?*Context = null;
    const options = [_]InitOption{
        .{ .option = .log_level, .value = .{ .log_level = .err } },
    };
    try libusb_init_context(&ctx, &options, options.len).result();
    try testing.expect(ctx != null);
    defer libusb_exit(ctx);
}

test "init context log callback" {
    var ctx: ?*Context = null;
    const options = [_]InitOption{
        .{
            .option = .log_cb,
            .value = .{
                .log_cb = (struct {
                    fn test_log_cb(_: ?*Context, _: LogLevel, _: [*c]const u8) callconv(.c) void {}
                }).test_log_cb,
            },
        },
    };

    try libusb_init_context(&ctx, &options, options.len).result();
    try testing.expect(ctx != null);
    defer libusb_exit(ctx);
}
