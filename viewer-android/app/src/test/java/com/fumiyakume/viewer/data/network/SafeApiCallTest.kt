package com.fumiyakume.viewer.data.network

import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.IOException
import java.net.SocketTimeoutException

class SafeApiCallTest {

    @Test
    fun safeApiCall_wraps_successful_result() = runTest {
        val result = safeApiCall { "ok" }

        assertEquals(ApiResult.Success("ok"), result)
    }

    @Test
    fun safeApiCall_wraps_ApiError_as_is() = runTest {
        val original = ApiError.ClientError(code = 400, message = "bad request")

        val result = safeApiCall { throw original }

        assertTrue(result is ApiResult.Error)
        assertSame(original, (result as ApiResult.Error).error)
    }

    @Test
    fun safeApiCall_maps_IOException_toNetworkError() = runTest {
        val result = safeApiCall<String> { throw IOException("io") }

        assertEquals(ApiResult.Error(ApiError.NetworkError), result)
    }

    @Test
    fun safeApiCall_maps_SocketTimeoutException_toTimeoutError() = runTest {
        val result = safeApiCall<String> { throw SocketTimeoutException("timeout") }

        assertEquals(ApiResult.Error(ApiError.TimeoutError), result)
    }
}

