package com.fumiyakume.viewer.data.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class ApiResultTest {

    @Test
    fun success_helpers_work() {
        val result: ApiResult<Int> = ApiResult.Success(42)

        assertTrue(result.isSuccess)
        assertFalse(result.isError)
        assertEquals(42, result.getOrNull())
        assertNull(result.errorOrNull())
    }

    @Test
    fun error_helpers_work() {
        val error = ApiError.NetworkError
        val result: ApiResult<Int> = ApiResult.Error(error)

        assertFalse(result.isSuccess)
        assertTrue(result.isError)
        assertNull(result.getOrNull())
        assertSame(error, result.errorOrNull())
    }

    @Test
    fun map_transformsSuccess_andPassesThroughError() {
        val success: ApiResult<Int> = ApiResult.Success(1)
        val error: ApiResult<Int> = ApiResult.Error(ApiError.TimeoutError)

        val mappedSuccess = success.map { it + 1 }
        val mappedError = error.map { it + 1 }

        assertEquals(ApiResult.Success(2), mappedSuccess)
        assertSame(error, mappedError)
    }

    @Test
    fun onSuccess_invokesOnlyForSuccess_andReturnsSameInstance() {
        var called = false
        val success: ApiResult<String> = ApiResult.Success("ok")
        val error: ApiResult<String> = ApiResult.Error(ApiError.NetworkError)

        val returnedSuccess = success.onSuccess { called = true }
        assertTrue(called)
        assertSame(success, returnedSuccess)

        called = false
        val returnedError = error.onSuccess { called = true }
        assertFalse(called)
        assertSame(error, returnedError)
    }

    @Test
    fun onError_invokesOnlyForError_andReturnsSameInstance() {
        var called = false
        val success: ApiResult<String> = ApiResult.Success("ok")
        val error: ApiResult<String> = ApiResult.Error(ApiError.NetworkError)

        val returnedSuccess = success.onError { called = true }
        assertFalse(called)
        assertSame(success, returnedSuccess)

        called = false
        val returnedError = error.onError { called = true }
        assertTrue(called)
        assertSame(error, returnedError)
    }
}

