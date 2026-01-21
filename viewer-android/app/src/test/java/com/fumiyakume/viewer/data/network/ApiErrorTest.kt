package com.fumiyakume.viewer.data.network

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import retrofit2.HttpException
import retrofit2.Response
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

class ApiErrorTest {

    @Test
    fun networkError_hasExpectedMessage() {
        assertEquals("ネットワークに接続できません", ApiError.NetworkError.message)
    }

    @Test
    fun timeoutError_hasExpectedMessage() {
        assertEquals("接続がタイムアウトしました", ApiError.TimeoutError.message)
    }

    @Test
    fun from_returnsSameInstance_forApiError() {
        val original = ApiError.ClientError(code = 404, message = "not found")

        val result = ApiError.from(original)

        assertSame(original, result)
    }

    @Test
    fun from_mapsSocketTimeout_toTimeoutError() {
        val result = ApiError.from(SocketTimeoutException("timeout"))

        assertSame(ApiError.TimeoutError, result)
    }

    @Test
    fun from_mapsUnknownHost_toNetworkError() {
        val result = ApiError.from(UnknownHostException("dns"))

        assertSame(ApiError.NetworkError, result)
    }

    @Test
    fun from_mapsIOException_toNetworkError() {
        val result = ApiError.from(IOException("io"))

        assertSame(ApiError.NetworkError, result)
    }

    @Test
    fun from_mapsHttpException_5xx_toServerError() {
        val result = ApiError.from(httpException(code = 503))

        assertTrue(result is ApiError.ServerError)
        assertEquals(503, (result as ApiError.ServerError).code)
    }

    @Test
    fun from_mapsHttpException_4xx_toClientError() {
        val result = ApiError.from(httpException(code = 404))

        assertTrue(result is ApiError.ClientError)
        assertEquals(404, (result as ApiError.ClientError).code)
    }

    @Test
    fun from_mapsHttpException_other_toUnknownError() {
        val result = ApiError.from(httpException(code = 600))

        assertTrue(result is ApiError.UnknownError)
    }

    @Test
    fun from_mapsUnknownException_withNullMessage_toUnknownError_defaultMessage() {
        val result = ApiError.from(RuntimeException())

        assertEquals(ApiError.UnknownError("不明なエラーが発生しました"), result)
    }

    private fun httpException(code: Int): HttpException {
        val responseBody = "error".toResponseBody("text/plain".toMediaType())
        return HttpException(Response.error<Any>(code, responseBody))
    }
}
