package com.yourname.turf.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AlertDialog
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.yourname.turf.databinding.BottomSheetHistoryBinding
import com.yourname.turf.databinding.ItemHistoryBinding
import com.yourname.turf.model.HistoryRepository
import com.yourname.turf.model.WalkSessionSummary

class HistoryBottomSheet : BottomSheetDialogFragment() {

    private var _binding: BottomSheetHistoryBinding? = null
    private val binding get() = _binding!!

    private lateinit var repository: HistoryRepository
    private var historyList = mutableListOf<WalkSessionSummary>()
    private lateinit var adapter: HistoryAdapter

    private var onDismissCallback: (() -> Unit)? = null

    fun setOnDismissListener(callback: () -> Unit) {
        this.onDismissCallback = callback
    }

    override fun onDismiss(dialog: android.content.DialogInterface) {
        super.onDismiss(dialog)
        onDismissCallback?.invoke()
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = BottomSheetHistoryBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        repository = HistoryRepository(requireContext())

        setupList()
        loadHistory()
        setupListeners()
    }

    private fun setupList() {
        binding.rvHistory.layoutManager = LinearLayoutManager(context)
        adapter = HistoryAdapter()
        binding.rvHistory.adapter = adapter
    }

    private fun loadHistory() {
        historyList.clear()
        historyList.addAll(repository.getHistory())

        if (historyList.isEmpty()) {
            binding.historyEmptyState.visibility = View.VISIBLE
            binding.rvHistory.visibility = View.GONE
            binding.tvClearAll.visibility = View.GONE
        } else {
            binding.historyEmptyState.visibility = View.GONE
            binding.rvHistory.visibility = View.VISIBLE
            binding.tvClearAll.visibility = View.VISIBLE
            adapter.notifyDataSetChanged()
        }
    }

    private fun setupListeners() {
        binding.tvClearAll.setOnClickListener {
            AlertDialog.Builder(requireContext())
                .setTitle("Clear History")
                .setMessage("Are you sure you want to delete all recorded walk history?")
                .setPositiveButton("Clear") { _, _ ->
                    repository.clearHistory()
                    loadHistory()
                }
                .setNegativeButton("Cancel", null)
                .show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    inner class HistoryAdapter : RecyclerView.Adapter<HistoryAdapter.HistoryViewHolder>() {

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): HistoryViewHolder {
            val itemBinding = ItemHistoryBinding.inflate(
                LayoutInflater.from(parent.context), parent, false
            )
            return HistoryViewHolder(itemBinding)
        }

        override fun onBindViewHolder(holder: HistoryViewHolder, position: Int) {
            holder.bind(historyList[position])
        }

        override fun getItemCount(): Int = historyList.size

        inner class HistoryViewHolder(private val itemBinding: ItemHistoryBinding) :
            RecyclerView.ViewHolder(itemBinding.root) {

            fun bind(session: WalkSessionSummary) {
                itemBinding.tvHistoryDate.text = session.dateTime
                itemBinding.tvHistoryLoops.text = if (session.loopCount == 1) "1 loop" else "${session.loopCount} loops"
                itemBinding.tvHistorySteps.text = session.steps.toString()
                itemBinding.tvHistoryStepsLbl.text = if (session.isStepEstimated) "Steps (est.)" else "Steps"
                itemBinding.tvHistoryDistance.text = String.format("%.2f km", session.distanceKm)
                
                val minutes = session.durationSeconds / 60
                val seconds = session.durationSeconds % 60
                itemBinding.tvHistoryDuration.text = String.format("%02d:%02d", minutes, seconds)
                
                itemBinding.tvHistoryCadence.text = "${session.cadence} SPM"
                itemBinding.tvHistoryElevation.text = String.format("%.1f m", session.elevationGainMetres)
            }
        }
    }

    companion object {
        const val TAG = "HistoryBottomSheet"
        fun newInstance() = HistoryBottomSheet()
    }
}
