/// @description Release optional off-screen background surface (YYC-safe)
if (is_real(surface) && surface_exists(surface)) {
        surface_free(surface);
};
surface = -1;