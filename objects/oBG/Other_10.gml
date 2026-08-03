/// @description surface create (YYC-safe)
size = [ room_width , room_height ];
if (!(is_real(surface) && surface_exists(surface))) {
        surface = surface_create(size[0], size[1]);
};