package com.fumiyakume.viewer.core.di

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class NetworkModuleTest {

    @Test
    fun provideJson_hasExpectedConfiguration() {
        val json = NetworkModule.provideJson()

        assertTrue(json.configuration.ignoreUnknownKeys)
        assertTrue(json.configuration.isLenient)
        assertTrue(json.configuration.encodeDefaults)
    }

    @Test
    fun provideOkHttpClient_setsTimeouts_andAddsBodyLoggingInterceptor() {
        val client = NetworkModule.provideOkHttpClient()

        assertEquals(120_000, client.connectTimeoutMillis.toLong())
        assertEquals(120_000, client.readTimeoutMillis.toLong())
        assertEquals(120_000, client.writeTimeoutMillis.toLong())

        val logging = client.interceptors.firstOrNull { it is HttpLoggingInterceptor } as? HttpLoggingInterceptor
        requireNotNull(logging)
        assertEquals(HttpLoggingInterceptor.Level.BODY, logging.level)
    }

    @Test
    fun provideRetrofit_usesBaseUrl_andProvidedOkHttpClient() {
        val client: OkHttpClient = NetworkModule.provideOkHttpClient()
        val json = NetworkModule.provideJson()

        val retrofit = NetworkModule.provideRetrofit(okHttpClient = client, json = json)

        assertEquals("https://toy-poodle-lover.vercel.app/", retrofit.baseUrl().toString())
        assertSame(client, retrofit.callFactory())
    }

    @Test
    fun provideApiService_createsRetrofitService() {
        val retrofit = NetworkModule.provideRetrofit(
            okHttpClient = NetworkModule.provideOkHttpClient(),
            json = NetworkModule.provideJson()
        )

        val service = NetworkModule.provideApiService(retrofit)

        assertTrue(service is com.fumiyakume.viewer.data.network.ApiService)
    }
}

