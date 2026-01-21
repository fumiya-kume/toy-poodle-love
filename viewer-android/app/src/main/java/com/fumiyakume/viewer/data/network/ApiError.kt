package com.fumiyakume.viewer.data.network

import retrofit2.HttpException
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

/**
 * APIエラーの種類を表すsealed class
 */
sealed class ApiError : Exception() {
    /** ネットワーク接続エラー */
    data object NetworkError : ApiError() {
        private fun readResolve(): Any = NetworkError
        override val message: String = "ネットワークに接続できません"
    }

    /** タイムアウトエラー */
    data object TimeoutError : ApiError() {
        private fun readResolve(): Any = TimeoutError
        override val message: String = "接続がタイムアウトしました"
    }

    /** サーバーエラー (5xx) */
    data class ServerError(val code: Int, override val message: String) : ApiError()

    /** クライアントエラー (4xx) */
    data class ClientError(val code: Int, override val message: String) : ApiError()

    /** API応答エラー (success=false) */
    data class ApiResponseError(override val message: String) : ApiError()

    /** 未知のエラー */
    data class UnknownError(override val message: String) : ApiError()

    companion object {
        /**
         * ExceptionをApiErrorに変換
         */
        fun from(throwable: Throwable): ApiError = when (throwable) {
            is ApiError -> throwable
            is SocketTimeoutException -> TimeoutError
            is UnknownHostException -> NetworkError
            is IOException -> NetworkError
            is HttpException -> {
                val code = throwable.code()
                val errorMessage = throwable.message() ?: "HTTPエラー: $code"
                when {
                    code in 500..599 -> ServerError(code, errorMessage)
                    code in 400..499 -> ClientError(code, errorMessage)
                    else -> UnknownError(errorMessage)
                }
            }
            else -> UnknownError(throwable.message ?: "不明なエラーが発生しました")
        }
    }
}

/**
 * API呼び出しの結果を表すsealed class
 */
sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val error: ApiError) : ApiResult<Nothing>()

    val isSuccess: Boolean get() = this is Success
    val isError: Boolean get() = this is Error

    fun getOrNull(): T? = (this as? Success)?.data
    fun errorOrNull(): ApiError? = (this as? Error)?.error

    inline fun <R> map(transform: (T) -> R): ApiResult<R> = when (this) {
        is Success -> Success(transform(data))
        is Error -> this
    }

    inline fun onSuccess(action: (T) -> Unit): ApiResult<T> {
        if (this is Success) action(data)
        return this
    }

    inline fun onError(action: (ApiError) -> Unit): ApiResult<T> {
        if (this is Error) action(error)
        return this
    }
}

/**
 * suspend関数をApiResultでラップ
 */
suspend fun <T> safeApiCall(apiCall: suspend () -> T): ApiResult<T> = try {
    ApiResult.Success(apiCall())
} catch (e: Exception) {
    ApiResult.Error(ApiError.from(e))
}
