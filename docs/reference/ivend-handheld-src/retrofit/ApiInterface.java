package com.citixsys.ivend_handheld.retrofit;

import com.citixsys.ivend_handheld.goodsRecceiptPurchaseOrder.GRPORequest;
import com.citixsys.ivend_handheld.goodsReturn.GoodsReturnRequest;
import com.citixsys.ivend_handheld.itemLookUp.PrintItemLabelsRequest;
import com.citixsys.ivend_handheld.purchaseOrder.PurchaseOrderRequest;
import com.citixsys.ivend_handheld.stockManagement.GoodsIssueRequest;
import com.citixsys.ivend_handheld.stockManagement.GoodsReceiptRequest;
import com.citixsys.ivend_handheld.stockManagement.LocTransferRequest;
import com.citixsys.ivend_handheld.stockTake.StockTakeRequest;
import com.citixsys.ivend_handheld.stockTransfer.StockTransferReceipt;
import com.citixsys.ivend_handheld.stockTransfer.StockTransferRequest;
import com.citixsys.ivend_handheld.stockTransfer.StockTransferShipment;
import com.citixsys.ivend_handheld.storePick.StorePickRequest;
import com.citixsys.ivend_handheld.storePick.StorePickings;
import com.citixsys.ivend_handheld.utility.commonDataModel.BarcodeInfo;
import com.citixsys.ivend_handheld.utility.commonDataModel.ItemPrice;
import com.citixsys.ivend_handheld.utility.commonDataModel.ProductDetails;
import java.util.ArrayList;
import java.util.List;
import okhttp3.ResponseBody;
import org.simpleframework.xml.strategy.Name;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.Query;

/* JADX INFO: loaded from: classes.dex */
public interface ApiInterface {
    @GET("ValidateUserWithDeviceId/?")
    Call<Boolean> doLogin(@Query("UserId") String str, @Query("Password") String str2, @Query("HardwareId") String str3, @Query("DeviceName") String str4);

    @POST("ExecuteQueries/")
    Call<String> executeQueries(@Body List<String> list, @Query("IsStoredProcedure") boolean z);

    @GET("GetBarCodeResolution/?")
    Call<BarcodeInfo> getBarcodeInfo(@Query("barCode") String str);

    @GET("CheckAPIConnection/")
    Call<String> getHealthCheckApi();

    @GET("GetItemSalesPrice/?")
    Call<ItemPrice> getItemSalesPrice(@Query("PRODUCTID") String str, @Query("CUSTOMERID") String str2, @Query("STOREID") String str3, @Query("UOMID") String str4, @Query("QUANTITY") double d);

    @GET("GetProduct/?")
    Call<ProductDetails> getProduct(@Query(Name.MARK) String str);

    @GET("GetQueryResult/?")
    Call<String> getQueryResult(@Query("queryText") String str);

    @GET("GetPickings/?")
    Call<ArrayList<StorePickings>> getStorePicking(@Query("warehouseId") String str, @Query("userId") String str2);

    @POST("SaveGoodsIssue/")
    Call<GoodsIssueRequest> sendGoodsIssueData(@Body GoodsIssueRequest goodsIssueRequest);

    @POST(" SaveGoodsReceipt/")
    Call<GoodsReceiptRequest> sendGoodsReceiptData(@Body GoodsReceiptRequest goodsReceiptRequest);

    @POST("SaveGoodsReceiptPO/")
    Call<GRPORequest> sendGoodsReceiptPO(@Body GRPORequest gRPORequest);

    @POST("SaveGoodsReturn/")
    Call<GoodsReturnRequest> sendGoodsReturnData(@Body GoodsReturnRequest goodsReturnRequest);

    @POST("SaveLocationStockTransfer/")
    Call<LocTransferRequest> sendLocationStockTransferData(@Body LocTransferRequest locTransferRequest);

    @POST("PrintItemLabels/")
    Call<ResponseBody> sendPrintItemLabelsData(@Body ArrayList<PrintItemLabelsRequest> arrayList);

    @POST("SavePurchaseOrder/")
    Call<PurchaseOrderRequest> sendPurchaseOrder(@Body PurchaseOrderRequest purchaseOrderRequest);

    @POST("SaveGoodsReceipt/")
    Call<StockTransferReceipt> sendSTReceiptData(@Body StockTransferReceipt stockTransferReceipt);

    @POST("SaveStockTransferRequest/")
    Call<StockTransferRequest> sendSTRequestData(@Body StockTransferRequest stockTransferRequest);

    @POST("SaveStockTransfer/")
    Call<StockTransferShipment> sendSTShipmentData(@Body StockTransferShipment stockTransferShipment);

    @POST("SaveInventoryCounting/")
    Call<StockTakeRequest> sendSockTakeData(@Body StockTakeRequest stockTakeRequest);

    @POST("SavePicking/")
    Call<StorePickRequest> sendStorePickRequest(@Body StorePickRequest storePickRequest);
}
