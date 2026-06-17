package com.citixsys.ivend_handheld.retrofit;

import com.citixsys.ivend_handheld.log.Mylog;
import com.citixsys.ivend_handheld.utils.AppSharedPreferences;
import com.citixsys.ivend_handheld.utils.JSONDateDeserializer;
import com.google.gson.GsonBuilder;
import java.io.IOException;
import java.util.Date;
import java.util.concurrent.TimeUnit;
import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Response;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.converter.simplexml.SimpleXmlConverterFactory;

/* JADX INFO: loaded from: classes.dex */
public class ApiClient {
    private static String BASEURL;
    private static Retrofit retrofit;

    public static String getBASEURL() {
        return BASEURL;
    }

    public static Retrofit getCheckConnection(String str, final String str2, final String str3) {
        Mylog.e("ApiClient", "url is " + BASEURL);
        try {
            BASEURL = str;
            new HttpLoggingInterceptor().setLevel(HttpLoggingInterceptor.Level.HEADERS);
            OkHttpClient.Builder timeout = new OkHttpClient.Builder().connectTimeout(2L, TimeUnit.MINUTES).writeTimeout(2L, TimeUnit.MINUTES).readTimeout(2L, TimeUnit.MINUTES);
            timeout.addInterceptor(new Interceptor() { // from class: com.citixsys.ivend_handheld.retrofit.ApiClient.1
                @Override // okhttp3.Interceptor
                public Response intercept(Interceptor.Chain chain) throws IOException {
                    return chain.proceed(chain.request().newBuilder().header("UserName", str2).header("Password", str3).build());
                }
            });
            retrofit = new Retrofit.Builder().baseUrl(str).addConverterFactory(SimpleXmlConverterFactory.create()).client(timeout.build()).build();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return retrofit;
    }

    private static Retrofit getXmlTableData(String str, final String str2, final String str3) {
        new HttpLoggingInterceptor().setLevel(HttpLoggingInterceptor.Level.BODY);
        String str4 = BASEURL;
        if (str4 == null || str4.equals("")) {
            BASEURL = str;
        }
        Mylog.e("ApiClient", "url is " + BASEURL);
        OkHttpClient.Builder timeout = new OkHttpClient.Builder().connectTimeout(2L, TimeUnit.MINUTES).readTimeout(2L, TimeUnit.MINUTES);
        timeout.addInterceptor(new Interceptor() { // from class: com.citixsys.ivend_handheld.retrofit.ApiClient.2
            @Override // okhttp3.Interceptor
            public Response intercept(Interceptor.Chain chain) throws IOException {
                return chain.proceed(chain.request().newBuilder().header("UserName", str2).header("Password", str3).build());
            }
        });
        Retrofit retrofitBuild = new Retrofit.Builder().baseUrl(BASEURL).client(timeout.build()).addConverterFactory(GsonConverterFactory.create()).build();
        retrofit = retrofitBuild;
        return retrofitBuild;
    }

    private static Retrofit getLoginClient(String str, final String str2, final String str3) {
        String str4 = BASEURL;
        if (str4 == null || str4.equals("")) {
            BASEURL = str;
        }
        Mylog.e("ApiClient", "url is " + BASEURL);
        Mylog.e("Auth User", "url is " + str2);
        Mylog.e("Auth ", "url is " + str3);
        new HttpLoggingInterceptor().setLevel(HttpLoggingInterceptor.Level.BODY);
        OkHttpClient.Builder timeout = new OkHttpClient.Builder().connectTimeout(5L, TimeUnit.MINUTES).readTimeout(5L, TimeUnit.MINUTES);
        timeout.addInterceptor(new Interceptor() { // from class: com.citixsys.ivend_handheld.retrofit.ApiClient.3
            @Override // okhttp3.Interceptor
            public Response intercept(Interceptor.Chain chain) throws IOException {
                return chain.proceed(chain.request().newBuilder().header("UserName", str2).header("Password", str3).build());
            }
        });
        OkHttpClient okHttpClientBuild = timeout.build();
        GsonBuilder gsonBuilder = new GsonBuilder();
        gsonBuilder.registerTypeAdapter(Date.class, new JSONDateDeserializer());
        Retrofit retrofitBuild = new Retrofit.Builder().baseUrl(BASEURL).addConverterFactory(GsonConverterFactory.create(gsonBuilder.create())).client(okHttpClientBuild).build();
        retrofit = retrofitBuild;
        return retrofitBuild;
    }

    public static ApiInterface getAPIClient() {
        return (ApiInterface) getLoginClient(AppSharedPreferences.getString("BASEURL"), AppSharedPreferences.getString("AuthUserName"), AppSharedPreferences.getString("AuthPwd")).create(ApiInterface.class);
    }

    public static ApiInterface getXMLAPIClient() {
        return (ApiInterface) getXmlTableData(AppSharedPreferences.getString("BASEURL"), AppSharedPreferences.getString("AuthUserName"), AppSharedPreferences.getString("AuthPwd")).create(ApiInterface.class);
    }
}
