package com.citixsys.ivend_handheld.utility.commonRetrofit;

import android.util.Log;
import android.util.Xml;
import com.citixsys.ivend_handheld.R;
import com.citixsys.ivend_handheld.base.BaseActivity;
import com.citixsys.ivend_handheld.base.BaseRetrofitHandler;
import com.citixsys.ivend_handheld.listener.CommonAPIInterface;
import com.citixsys.ivend_handheld.log.Mylog;
import com.citixsys.ivend_handheld.retrofit.ApiClient;
import com.citixsys.ivend_handheld.retrofit.ApiInterface;
import com.citixsys.ivend_handheld.stockTake.StockTakeRequest;
import com.citixsys.ivend_handheld.utility.CommonMethods;
import com.citixsys.ivend_handheld.utility.commonDataModel.BarcodeInfo;
import com.citixsys.ivend_handheld.utility.commonDataModel.ItemPrice;
import com.citixsys.ivend_handheld.utility.commonDataModel.ProductDetails;
import com.citixsys.ivend_handheld.utility.commonDataModel.ProductDetailsBean;
import com.citixsys.ivend_handheld.utility.commonXmlParser.ProductDetailsXMLHandler;
import com.citixsys.ivend_handheld.utils.AndroidUtils;
import com.citixsys.ivend_handheld.utils.AppPreferences;
import com.citixsys.ivend_handheld.utils.AppSharedPreferences;
import com.citixsys.ivend_handheld.utils.CommonUtils;
import com.citixsys.ivend_handheld.utils.NetworkUtils;
import com.citixsys.ivend_handheld.utils.StringUtils;
import com.google.gson.Gson;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/* JADX INFO: loaded from: classes.dex */
public class ProductRetrofitHandler extends BaseRetrofitHandler {
    private static final String TAG = "com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler";
    private ApiInterface apiInterface;
    private WeakReference<StockTakeRetrofitListener> mDataWeakListener;
    private WeakReference<ProductRetrofitListener> mWeakListener;

    public interface ProductRetrofitListener {
        void onBarcodeInfoReceived(ProductDetailsBean productDetailsBean, boolean z);

        void onItemPriceReceived(ItemPrice itemPrice);

        void onProductReceived(ProductDetails productDetails);
    }

    public interface StockTakeRetrofitListener extends CommonAPIInterface {
        void onStockTakeDataReceived(StockTakeRequest stockTakeRequest);
    }

    public ProductRetrofitHandler(BaseActivity baseActivity) {
        super(baseActivity);
    }

    public void registerInitializationListener(ProductRetrofitListener productRetrofitListener) {
        this.mWeakListener = new WeakReference<>(productRetrofitListener);
    }

    public void registerStockTakeListener(StockTakeRetrofitListener stockTakeRetrofitListener) {
        this.mDataWeakListener = new WeakReference<>(stockTakeRetrofitListener);
    }

    public void getProductDetails(String str) {
        ApiInterface aPIClient = ApiClient.getAPIClient();
        this.apiInterface = aPIClient;
        Call<ProductDetails> product = aPIClient.getProduct(str);
        String str2 = TAG;
        Mylog.e(str2, "getProductDetails id=" + str);
        Mylog.e(str2, "getProductDetails URL=" + product.request().url());
        product.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.1
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ProductDetails productDetails;
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetails onResponse = " + response.code());
                if (response.code() != 200 || (productDetails = (ProductDetails) response.body()) == null) {
                    return;
                }
                try {
                    if (StringUtils.isNullOrEmpty(productDetails.getMessage())) {
                        productRetrofitListener.onProductReceived(productDetails);
                    }
                } catch (Exception e) {
                    Mylog.e(ProductRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetails onFailure=  " + th.getMessage());
            }
        });
    }

    public void getBarcodeInfo(final String str, final int i) {
        String str2 = TAG;
        Log.e(str2, "Time Requested");
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<BarcodeInfo> barcodeInfo = xMLAPIClient.getBarcodeInfo(str);
        Mylog.e(str2, " getBarcodeInfo URL=" + NetworkUtils.bodyToString(barcodeInfo.request().body()));
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        barcodeInfo.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.2
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                Log.e(ProductRetrofitHandler.TAG, "Time Received");
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                Mylog.e(ProductRetrofitHandler.TAG, "getBarcodeInfo onResponse = " + new Gson().toJson(response.body()));
                if (response.code() == 200) {
                    BarcodeInfo barcodeInfo2 = (BarcodeInfo) response.body();
                    if (barcodeInfo2 != null) {
                        try {
                            if (StringUtils.isNullOrEmpty(barcodeInfo2.getMessage())) {
                                ProductRetrofitHandler.this.getProductDetailByBarcodeID(barcodeInfo2, str, i);
                                return;
                            }
                            return;
                        } catch (Exception e) {
                            Mylog.e(ProductRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                            return;
                        }
                    }
                    return;
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
                ProductRetrofitHandler.this.endProgressDialog();
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ProductRetrofitHandler.this.endProgressDialog();
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
                Mylog.e(ProductRetrofitHandler.TAG, "getBarcodeInfo onFailure = " + th.getMessage());
            }
        });
    }

    public void getProductDetailByBarcodeID(final BarcodeInfo barcodeInfo, final String str, int i) {
        String itemQuery = getItemQuery(barcodeInfo, i);
        Log.e(TAG, "getProductDetailByBarcodeID Query = " + itemQuery);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        xMLAPIClient.getQueryResult(itemQuery).enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.3
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                Log.e(ProductRetrofitHandler.TAG, "Time Received");
                ProductRetrofitHandler.this.endProgressDialog();
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetailByBarcodeID onResponse = " + new Gson().toJson(response.body()));
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ProductDetailsXMLHandler productDetailsXMLHandler = new ProductDetailsXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, productDetailsXMLHandler);
                        ArrayList<ProductDetailsBean> searchTransactionsResponseList = productDetailsXMLHandler.getSearchTransactionsResponseList();
                        if (!CommonUtils.isListEmptyOrNull(searchTransactionsResponseList)) {
                            ProductDetailsBean productDetailsBean = searchTransactionsResponseList.get(0);
                            if (productDetailsBean != null) {
                                productDetailsBean.setPrice(barcodeInfo.getPrice().doubleValue());
                                productDetailsBean.setQty(barcodeInfo.getQuantity().doubleValue());
                                Log.e(ProductRetrofitHandler.TAG, "Barcode info uom =" + barcodeInfo.getUomId());
                                Log.e(ProductRetrofitHandler.TAG, "product info uom =" + productDetailsBean.getUomId());
                                if (!StringUtils.isNullOrEmptyKey(barcodeInfo.getUomId())) {
                                    productDetailsBean.setUomId(barcodeInfo.getUomId());
                                }
                                if (productDetailsBean.getItemManageType() == 2) {
                                    productDetailsBean.setSerialBatchNumber(barcodeInfo.getSerialNumber());
                                }
                                if (productDetailsBean.getItemManageType() == 3) {
                                    productDetailsBean.setSerialBatchNumber(barcodeInfo.getBatchNumber());
                                }
                                productDetailsBean.setSearchBarcode(str);
                                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetailByBarcodeID Product Size=" + searchTransactionsResponseList.size());
                                productRetrofitListener.onBarcodeInfoReceived(productDetailsBean, true);
                                return;
                            }
                            productRetrofitListener.onBarcodeInfoReceived(null, false);
                            return;
                        }
                        productRetrofitListener.onBarcodeInfoReceived(null, false);
                        return;
                    } catch (Exception e) {
                        Mylog.e(ProductRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                        return;
                    }
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ProductRetrofitHandler.this.endProgressDialog();
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetailByBarcodeID onFailure = " + th.getMessage());
            }
        });
    }

    private static String getItemQuery(BarcodeInfo barcodeInfo, int i) {
        if (i == 1002 || i == 1005 || i == 1010 || i == 1012) {
            return "SELECT InvProduct.ID, InvProduct.Description,InvProduct.AllowFractionalQuantity, InvProduct.IsNonStock,InvProduct.IsGiftCertificate,InvProduct.IsMatrixItem, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, InvProduct.UOMGroupKey, InvUOM.Id UOMId, InvProduct.IsPurchasable  \nFROM InvProduct WITH (NOLOCK)\nLEFT OUTER JOIN InvUOMGroup WITH (NOLOCK) ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey\nLEFT OUTER JOIN InvUOM WITH (NOLOCK) ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey WHERE InvProduct.Id= '" + barcodeInfo.getProductId() + "'";
        }
        return "SELECT InvProduct.ID, InvProduct.Description,InvProduct.AllowFractionalQuantity, InvProduct.IsNonStock,InvProduct.IsGiftCertificate,InvProduct.IsMatrixItem, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, InvProduct.UOMGroupKey, InvUOM.Id UOMId, InvProduct.IsPurchasable  \nFROM InvProduct WITH (NOLOCK)\nLEFT OUTER JOIN InvUOMGroup WITH (NOLOCK) ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey\nLEFT OUTER JOIN InvUOM WITH (NOLOCK) ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey WHERE InvProduct.Id= '" + barcodeInfo.getProductId() + "' AND InvProduct.IsOnHold = 0";
    }

    public void saveStockTakeData(StockTakeRequest stockTakeRequest) {
        ApiInterface aPIClient = ApiClient.getAPIClient();
        this.apiInterface = aPIClient;
        Call<StockTakeRequest> callSendSockTakeData = aPIClient.sendSockTakeData(stockTakeRequest);
        Mylog.e(TAG, "saveStockTakeData onRequest=  " + NetworkUtils.bodyToString(callSendSockTakeData.request().body()));
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        callSendSockTakeData.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.4
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ProductRetrofitHandler.this.endProgressDialog();
                StockTakeRetrofitListener stockTakeRetrofitListener = (StockTakeRetrofitListener) ProductRetrofitHandler.this.mDataWeakListener.get();
                if (stockTakeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ProductRetrofitHandler.TAG, "saveStockTakeData onResponse = " + new Gson().toJson(response.body()));
                if (response.code() == 200) {
                    StockTakeRequest stockTakeRequest2 = (StockTakeRequest) response.body();
                    try {
                        if (stockTakeRequest2 != null) {
                            if (StringUtils.isSuccess(stockTakeRequest2.getMessage())) {
                                stockTakeRetrofitListener.onStockTakeDataReceived(stockTakeRequest2);
                                return;
                            } else {
                                stockTakeRetrofitListener.showCommonAlertMessage(R.string.PO_Alert, R.string.Common_ServerErrorMsg, stockTakeRequest2.getMessage());
                                return;
                            }
                        }
                        stockTakeRetrofitListener.showCommonAlertMessage(R.string.PO_Alert, R.string.Common_ServerErrorMsg, null);
                    } catch (Exception e) {
                        Mylog.e(ProductRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                        stockTakeRetrofitListener.showCommonAlertMessage(R.string.PO_Alert, R.string.Common_ServerErrorMsg, null);
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ProductRetrofitHandler.this.endProgressDialog();
                StockTakeRetrofitListener stockTakeRetrofitListener = (StockTakeRetrofitListener) ProductRetrofitHandler.this.mDataWeakListener.get();
                if (stockTakeRetrofitListener == null) {
                    return;
                }
                stockTakeRetrofitListener.showCommonAlertMessage(R.string.PO_Alert, R.string.Common_ServerErrorMsg, th.getMessage());
                Mylog.e(ProductRetrofitHandler.TAG, "saveStockTakeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getItemSalesPrice(String str, String str2, String str3, String str4, double d) {
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<ItemPrice> itemSalesPrice = xMLAPIClient.getItemSalesPrice(str, str2, str3, str4, d);
        Mylog.e(TAG, "getItemSalesPrice URL=" + itemSalesPrice.request().url());
        itemSalesPrice.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.5
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemPrice itemPrice;
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                Mylog.e(ProductRetrofitHandler.TAG, "getItemSalesPrice onResponse = " + new Gson().toJson(response.body()));
                if (response.code() != 200 || (itemPrice = (ItemPrice) response.body()) == null) {
                    return;
                }
                try {
                    if (itemPrice.getMessage() != null) {
                        productRetrofitListener.onItemPriceReceived(itemPrice);
                    }
                } catch (Exception e) {
                    Mylog.e(ProductRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                Mylog.e(ProductRetrofitHandler.TAG, "getItemSalesPrice onFailure = " + th.getMessage());
            }
        });
    }

    public void getBarcodeInfoForPO(final String str, final String str2, final boolean z) {
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<BarcodeInfo> barcodeInfo = xMLAPIClient.getBarcodeInfo(str);
        Mylog.e(TAG, " getBarcodeInfo URL=" + NetworkUtils.bodyToString(barcodeInfo.request().body()));
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        barcodeInfo.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.6
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                Mylog.e(ProductRetrofitHandler.TAG, "getBarcodeInfo onResponse = " + new Gson().toJson(response.body()));
                if (response.code() == 200) {
                    BarcodeInfo barcodeInfo2 = (BarcodeInfo) response.body();
                    if (barcodeInfo2 != null) {
                        try {
                            if (StringUtils.isNullOrEmpty(barcodeInfo2.getMessage())) {
                                ProductRetrofitHandler.this.getProductDetailByBarcodeIDForPO(barcodeInfo2.getProductId(), barcodeInfo2.getPrice().doubleValue(), barcodeInfo2.getQuantity().doubleValue(), str2, z, barcodeInfo2.getUomId(), str);
                                return;
                            }
                            return;
                        } catch (Exception e) {
                            Mylog.e(ProductRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                            return;
                        }
                    }
                    return;
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
                ProductRetrofitHandler.this.endProgressDialog();
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ProductRetrofitHandler.this.endProgressDialog();
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
                Mylog.e(ProductRetrofitHandler.TAG, "getBarcodeInfo onFailure = " + th.getMessage());
            }
        });
    }

    public void getProductDetailByBarcodeIDForPO(String str, final double d, final double d2, String str2, boolean z, final String str3, final String str4) {
        String str5;
        if (!z) {
            str5 = "SELECT InvProduct.ID, InvProduct.Description,InvProduct.AllowFractionalQuantity, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, InvProduct.UOMGroupKey, InvUOM.Id UOMId, InvProduct.IsPurchasable, TaxTaxCode.Id AS PurchaseTaxCodeId  FROM InvProduct WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup WITH (NOLOCK) ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey\nLEFT OUTER JOIN InvUOM WITH (NOLOCK) ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey LEFT OUTER JOIN TaxTaxCode  WITH (NOLOCK) ON TaxTaxCode.TaxCodeKey = InvProduct.PurchaseTaxCodeKey";
        } else {
            str5 = "SELECT InvProduct.ID, InvProduct.Description,InvProduct.AllowFractionalQuantity, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, InvProduct.UOMGroupKey, InvUOM.Id UOMId, InvProduct.IsPurchasable, TaxTaxCode.Id AS PurchaseTaxCodeId  FROM InvProduct WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup WITH (NOLOCK) ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey\nLEFT OUTER JOIN InvUOM WITH (NOLOCK) ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey LEFT OUTER JOIN TaxTaxCode  WITH (NOLOCK) ON TaxTaxCode.TaxCodeKey = InvProduct.PurchaseTaxCodeKey Inner Join PurVendorProduct On InvProduct.ProductKey = PurVendorProduct.ProductKey And PurVendorProduct.IsDeleted = 'FALSE' And PurVendorProduct.VendorKey = (Select VendorKey From PurVendor WHERE Id = '" + str2 + "')";
        }
        String str6 = str5 + " WHERE InvProduct.Id= '" + str + "' AND InvProduct.IsOnHold = 0";
        if (AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str6 = str6 + " AND ProductKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + AppPreferences.getSubsidiaryKey() + "' AND SourceType=46) ";
        }
        Mylog.e(TAG, "getProductDetailByBarcodeID Query = " + str6);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        xMLAPIClient.getQueryResult(str6).enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.7
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ProductRetrofitHandler.this.endProgressDialog();
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetailByBarcodeID onResponse = " + new Gson().toJson(response.body()));
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ProductDetailsXMLHandler productDetailsXMLHandler = new ProductDetailsXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, productDetailsXMLHandler);
                        ArrayList<ProductDetailsBean> searchTransactionsResponseList = productDetailsXMLHandler.getSearchTransactionsResponseList();
                        if (!CommonUtils.isListEmptyOrNull(searchTransactionsResponseList)) {
                            ProductDetailsBean productDetailsBean = searchTransactionsResponseList.get(0);
                            if (productDetailsBean != null) {
                                productDetailsBean.setPrice(d);
                                productDetailsBean.setQty(d2);
                                if (!StringUtils.isNullOrEmptyKey(str3)) {
                                    productDetailsBean.setUomId(str3);
                                }
                                productDetailsBean.setSearchBarcode(str4);
                                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetailByBarcodeID Product Size=" + searchTransactionsResponseList.size());
                                productRetrofitListener.onBarcodeInfoReceived(productDetailsBean, true);
                                return;
                            }
                            productRetrofitListener.onBarcodeInfoReceived(null, false);
                            return;
                        }
                        productRetrofitListener.onBarcodeInfoReceived(null, false);
                        return;
                    } catch (Exception e) {
                        Mylog.e(ProductRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                        return;
                    }
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ProductRetrofitHandler.this.endProgressDialog();
                ProductRetrofitListener productRetrofitListener = (ProductRetrofitListener) ProductRetrofitHandler.this.mWeakListener.get();
                if (productRetrofitListener == null) {
                    return;
                }
                productRetrofitListener.onBarcodeInfoReceived(null, false);
                Mylog.e(ProductRetrofitHandler.TAG, "getProductDetailByBarcodeID onFailure = " + th.getMessage());
            }
        });
    }
}
