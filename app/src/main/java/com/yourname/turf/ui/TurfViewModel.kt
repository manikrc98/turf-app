package com.yourname.turf.ui

import android.content.ComponentName
import android.content.ServiceConnection
import android.os.IBinder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yourname.turf.model.SessionStatus
import com.yourname.turf.model.TurfSessionState
import com.yourname.turf.service.TurfTrackerService
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

class TurfViewModel : ViewModel() {

    private val _serviceBoundState = MutableStateFlow<TurfTrackerService?>(null)
    val serviceBoundState: StateFlow<TurfTrackerService?> = _serviceBoundState.asStateFlow()

    private val _uiState = MutableStateFlow(TurfSessionState())
    val uiState: StateFlow<TurfSessionState> = _uiState.asStateFlow()

    // SharedFlow to deliver one-off notifications (e.g., Loop completed -> Snackbar)
    private val _loopCapturedEvent = MutableSharedFlow<com.yourname.turf.model.TurfLoop>(replay = 0)
    val loopCapturedEvent: SharedFlow<com.yourname.turf.model.TurfLoop> = _loopCapturedEvent.asSharedFlow()

    // Stores the snapshot of the session summary after it has ended
    var lastSummaryState: TurfSessionState? = null
        private set
    var lastSummaryDurationSeconds: Long = 0L
        private set

    val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as? TurfTrackerService.TurfBinder
            val boundService = binder?.getService() ?: return
            _serviceBoundState.value = boundService
            
            // Connect listener for loop events
            boundService.setOnLoopCapturedListener { loop ->
                viewModelScope.launch {
                    _loopCapturedEvent.emit(loop)
                }
            }

            // Collect state updates from service
            viewModelScope.launch {
                boundService.sessionState.collectLatest { state ->
                    _uiState.value = state
                }
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            _serviceBoundState.value = null
        }
    }

    fun startWalk() {
        _serviceBoundState.value?.startWalk()
    }

    fun pauseWalk() {
        _serviceBoundState.value?.pauseWalk()
    }

    fun resumeWalk() {
        _serviceBoundState.value?.resumeWalk()
    }

    fun endWalk() {
        val service = _serviceBoundState.value ?: return
        
        // Save the summary before stopping the service
        val finalState = service.sessionState.value
        lastSummaryState = finalState
        lastSummaryDurationSeconds = service.getSessionDurationSeconds()
        
        service.endWalk()
    }

    fun clearSummary() {
        lastSummaryState = null
        lastSummaryDurationSeconds = 0L
    }

    fun nameLoop(loopId: String, name: String) {
        _serviceBoundState.value?.nameLoop(loopId, name)
    }
}
