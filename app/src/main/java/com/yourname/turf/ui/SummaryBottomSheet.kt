package com.yourname.turf.ui

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.core.content.FileProvider
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.yourname.turf.databinding.BottomSheetSummaryBinding
import java.io.File
import java.io.FileOutputStream

class SummaryBottomSheet : BottomSheetDialogFragment() {

    private var _binding: BottomSheetSummaryBinding? = null
    private val binding get() = _binding!!

    private var mapSnapshot: Bitmap? = null
    private var steps: Int = 0
    private var isStepEstimated: Boolean = false
    private var distanceKm: Double = 0.0
    private var loops: Int = 0
    private var durationSeconds: Long = 0L
    private var cadence: Int = 0
    private var elevationGainMetres: Double = 0.0

    private var onDoneCallback: (() -> Unit)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isCancelable = false
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = BottomSheetSummaryBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupStats()
        setupButtons()
    }

    fun setSessionData(
        snapshot: Bitmap?,
        steps: Int,
        isStepEstimated: Boolean,
        distanceKm: Double,
        loops: Int,
        durationSeconds: Long,
        cadence: Int,
        elevationGainMetres: Double,
        onDone: () -> Unit
    ) {
        this.mapSnapshot = snapshot
        this.steps = steps
        this.isStepEstimated = isStepEstimated
        this.distanceKm = distanceKm
        this.loops = loops
        this.durationSeconds = durationSeconds
        this.cadence = cadence
        this.elevationGainMetres = elevationGainMetres
        this.onDoneCallback = onDone
    }

    private fun setupStats() {
        binding.tvSummarySteps.text = if (isStepEstimated) "$steps (est.)" else steps.toString()
        binding.tvSummaryDistance.text = String.format("%.2f km", distanceKm)
        
        val minutes = durationSeconds / 60
        val seconds = durationSeconds % 60
        binding.tvSummaryDuration.text = String.format("%02d:%02d", minutes, seconds)
        
        binding.tvSummaryLoops.text = loops.toString()
        binding.tvSummaryCadence.text = cadence.toString()
        binding.tvSummaryElevation.text = String.format("%.1f", elevationGainMetres)

        if (mapSnapshot != null) {
            binding.ivMapSnapshot.setImageBitmap(mapSnapshot)
            binding.tvSnapshotPlaceholder.visibility = View.GONE
        } else {
            binding.tvSnapshotPlaceholder.visibility = View.VISIBLE
            binding.tvSnapshotPlaceholder.text = "Snapshot unavailable"
        }

        if (loops == 0) {
            binding.tvSummaryNudge.visibility = View.VISIBLE
        } else {
            binding.tvSummaryNudge.visibility = View.GONE
        }
    }

    private fun setupButtons() {
        binding.btnDone.setOnClickListener {
            onDoneCallback?.invoke()
            dismiss()
        }

        binding.btnShare.setOnClickListener {
            shareSummaryCard()
        }
    }

    private fun shareSummaryCard() {
        val cardWidth = 800
        val cardHeight = 1100
        val bitmap = Bitmap.createBitmap(cardWidth, cardHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // 1. Draw Background
        val bgPaint = Paint().apply {
            color = Color.parseColor("#F5F0E8")
            style = Paint.Style.FILL
        }
        canvas.drawRect(0f, 0f, cardWidth.toFloat(), cardHeight.toFloat(), bgPaint)

        // 2. Draw Green Header
        val headerPaint = Paint().apply {
            color = Color.parseColor("#2E7D32")
            style = Paint.Style.FILL
        }
        canvas.drawRect(0f, 0f, cardWidth.toFloat(), 180f, headerPaint)

        // 3. Draw Branding
        val textPaint = Paint().apply {
            color = Color.WHITE
            textSize = 44f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }
        canvas.drawText("TURF — Walk Session", 40f, 105f, textPaint)

        val subtextPaint = Paint().apply {
            color = Color.parseColor("#E8F5E9")
            textSize = 24f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            isAntiAlias = true
        }
        val minutes = durationSeconds / 60
        val seconds = durationSeconds % 60
        val durationStr = String.format("Duration: %02d:%02d", minutes, seconds)
        canvas.drawText(durationStr, 40f, 145f, subtextPaint)

        // 4. Draw Map Snapshot
        val mapTop = 220f
        val mapHeight = 450f
        val mapBottom = mapTop + mapHeight
        val mapRect = RectF(40f, mapTop, (cardWidth - 40).toFloat(), mapBottom)
        
        val borderPaint = Paint().apply {
            color = Color.parseColor("#E0E0E0")
            style = Paint.Style.STROKE
            strokeWidth = 4f
        }
        
        if (mapSnapshot != null) {
            canvas.drawBitmap(mapSnapshot!!, null, mapRect, Paint(Paint.FILTER_BITMAP_FLAG))
            canvas.drawRect(mapRect, borderPaint)
        } else {
            val emptyPaint = Paint().apply {
                color = Color.parseColor("#E0E0E0")
                style = Paint.Style.FILL
            }
            canvas.drawRect(mapRect, emptyPaint)
            val placeholderPaint = Paint().apply {
                color = Color.DKGRAY
                textSize = 28f
                isAntiAlias = true
            }
            canvas.drawText("Map Snapshot Unavailable", 200f, mapTop + 240f, placeholderPaint)
        }

        // 5. Draw Stat Card Block
        val statsTop = mapBottom + 40f
        val statsBgPaint = Paint().apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        val statsRect = RectF(40f, statsTop, (cardWidth - 40).toFloat(), cardHeight - 50f)
        canvas.drawRoundRect(statsRect, 20f, 20f, statsBgPaint)
        
        val statsBorderPaint = Paint().apply {
            color = Color.parseColor("#2E7D32")
            style = Paint.Style.STROKE
            strokeWidth = 3f
        }
        canvas.drawRoundRect(statsRect, 20f, 20f, statsBorderPaint)

        val statValuePaint = Paint().apply {
            color = Color.parseColor("#212121")
            textSize = 34f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }
        
        val statLabelPaint = Paint().apply {
            color = Color.parseColor("#757575")
            textSize = 22f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            isAntiAlias = true
        }

        val stepValue = if (isStepEstimated) "$steps (est.)" else steps.toString()
        val distValue = String.format("%.2f km", distanceKm)
        
        // Row 1: Steps & Distance
        canvas.drawText("Steps", 80f, statsTop + 55f, statLabelPaint)
        canvas.drawText(stepValue, 80f, statsTop + 95f, statValuePaint)

        canvas.drawText("Distance", 440f, statsTop + 55f, statLabelPaint)
        canvas.drawText(distValue, 440f, statsTop + 95f, statValuePaint)

        // Row 2: Turf loops & Duration
        canvas.drawText("Turf loops", 80f, statsTop + 150f, statLabelPaint)
        val loopValuePaint = Paint().apply {
            color = Color.parseColor("#2E7D32")
            textSize = 34f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }
        canvas.drawText(loops.toString(), 80f, statsTop + 190f, loopValuePaint)

        canvas.drawText("Duration", 440f, statsTop + 150f, statLabelPaint)
        val durationValueStr = String.format("%02d:%02d", minutes, seconds)
        canvas.drawText(durationValueStr, 440f, statsTop + 190f, statValuePaint)

        // Row 3: Cadence & Elevation Gain
        canvas.drawText("Cadence", 80f, statsTop + 245f, statLabelPaint)
        canvas.drawText("$cadence SPM", 80f, statsTop + 285f, statValuePaint)

        canvas.drawText("Elevation Gain", 440f, statsTop + 245f, statLabelPaint)
        val elevationStr = String.format("%.1f m", elevationGainMetres)
        canvas.drawText(elevationStr, 440f, statsTop + 285f, statValuePaint)

        // 6. Compress and Share
        try {
            val cachePath = File(requireContext().cacheDir, "images")
            cachePath.mkdirs()
            val imageFile = File(cachePath, "turf_walk.png")
            val stream = FileOutputStream(imageFile)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.close()

            val contentUri = FileProvider.getUriForFile(
                requireContext(),
                "${requireContext().packageName}.fileprovider",
                imageFile
            )

            if (contentUri != null) {
                val shareIntent = Intent().apply {
                    action = Intent.ACTION_SEND
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    putExtra(Intent.EXTRA_STREAM, contentUri)
                    type = "image/png"
                }
                startActivity(Intent.createChooser(shareIntent, "Share Turf Walk"))
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(context, "Failed to share card image", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        const val TAG = "SummaryBottomSheet"
        
        fun newInstance(): SummaryBottomSheet {
            return SummaryBottomSheet()
        }
    }
}
