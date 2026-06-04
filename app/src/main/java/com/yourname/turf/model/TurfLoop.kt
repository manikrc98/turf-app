package com.yourname.turf.model

import com.google.android.gms.maps.model.LatLng
import java.util.UUID

data class TurfLoop(
    val id: String = UUID.randomUUID().toString(),
    val name: String? = null,
    val points: List<LatLng>
)
