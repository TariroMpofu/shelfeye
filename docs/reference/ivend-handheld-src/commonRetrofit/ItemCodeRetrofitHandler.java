package com.citixsys.ivend_handheld.utility.commonRetrofit;

import android.util.Log;
import android.util.Xml;
import com.citixsys.ivend_handheld.R;
import com.citixsys.ivend_handheld.base.BaseActivity;
import com.citixsys.ivend_handheld.base.BaseRetrofitHandler;
import com.citixsys.ivend_handheld.log.Mylog;
import com.citixsys.ivend_handheld.login.SiteBean;
import com.citixsys.ivend_handheld.retrofit.ApiClient;
import com.citixsys.ivend_handheld.retrofit.ApiInterface;
import com.citixsys.ivend_handheld.utility.CommonMethods;
import com.citixsys.ivend_handheld.utility.commonDataModel.ItemCodeBean;
import com.citixsys.ivend_handheld.utility.commonXmlParser.ItemCodeXMLHandler;
import com.citixsys.ivend_handheld.utils.AndroidUtils;
import com.citixsys.ivend_handheld.utils.AppPreferences;
import com.citixsys.ivend_handheld.utils.AppSharedPreferences;
import com.google.gson.Gson;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/* JADX INFO: loaded from: classes.dex */
public class ItemCodeRetrofitHandler extends BaseRetrofitHandler {
    private static final String TAG = "com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler";
    private ApiInterface apiInterface;
    private WeakReference<ItemCodeRetrofitListener> mWeakListener;

    public interface ItemCodeRetrofitListener {
        void onItemCodeArrayReceived(List<ItemCodeBean> list);
    }

    public ItemCodeRetrofitHandler(BaseActivity baseActivity) {
        super(baseActivity);
    }

    public void registerInitializationListener(ItemCodeRetrofitListener itemCodeRetrofitListener) {
        this.mWeakListener = new WeakReference<>(itemCodeRetrofitListener);
    }

    public void getItemLookUpData() {
        String str;
        String str2 = TAG;
        Log.e(str2, "Time Requested");
        if (!AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str = "SELECT TOP 1000 InvProduct.ID, InvProduct.Description,InvProduct.AllowFractionalQuantity, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage,InvProduct.UOMGroupKey, \nInvUOM.Id UOMId \nFROM InvProduct WITH (NOLOCK) \nLEFT OUTER JOIN InvUOMGroup ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey\nLEFT OUTER JOIN InvUOM ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey\nWHERE  InvProduct.IsDeleted=0 AND InvProduct.IsGiftCertificate=0 AND InvProduct.IsMatrixItem=0";
        } else {
            str = "SELECT TOP 1000 InvProduct.ID, InvProduct.Description,InvProduct.AllowFractionalQuantity, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage,InvProduct.UOMGroupKey, \nInvUOM.Id UOMId \nFROM InvProduct WITH (NOLOCK) \nLEFT OUTER JOIN InvUOMGroup ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey\nLEFT OUTER JOIN InvUOM ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey\nWHERE  InvProduct.IsDeleted=0 AND InvProduct.IsGiftCertificate=0 AND InvProduct.IsMatrixItem=0 AND ProductKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + AppSharedPreferences.getString("SubsidiaryKey", "") + "' AND SourceType=46) ";
        }
        String str3 = str + " ORDER BY ID";
        Log.e(str2, "getItemLookupItemCodeData Query = " + str3);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str3);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.1
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                Log.e(ItemCodeRetrofitHandler.TAG, "Time Received");
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemLookupItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    String str4 = (String) response.body();
                    try {
                        Log.e(ItemCodeRetrofitHandler.TAG, "Parsing start");
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser(str4);
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        ArrayList<ItemCodeBean> searchTransactionsResponseList = itemCodeXMLHandler.getSearchTransactionsResponseList();
                        Log.e(ItemCodeRetrofitHandler.TAG, "Parsing end");
                        itemCodeRetrofitListener.onItemCodeArrayReceived(searchTransactionsResponseList);
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemLookupItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getItemLookupItemCodeData() {
        String str;
        if (!AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str = "SELECT TOP 1000 InvProduct.ID, InvProduct.BasePrice,InvProduct.Description,InvProduct.AllowFractionalQuantity, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage,InvProduct.UOMGroupKey, InvUOM.Id UOMId FROM InvProduct WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey LEFT OUTER JOIN InvUOM ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey WHERE InvProduct.IsNonStock=0 AND InvProduct.IsDeleted=0 AND InvProduct.IsGiftCertificate=0 AND InvProduct.IsMatrixItem=0 AND InvProduct.IsOnHold = 0";
        } else {
            str = "SELECT TOP 1000 InvProduct.ID, InvProduct.BasePrice,InvProduct.Description,InvProduct.AllowFractionalQuantity, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage,InvProduct.UOMGroupKey, InvUOM.Id UOMId FROM InvProduct WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey LEFT OUTER JOIN InvUOM ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey WHERE InvProduct.IsNonStock=0 AND InvProduct.IsDeleted=0 AND InvProduct.IsGiftCertificate=0 AND InvProduct.IsMatrixItem=0 AND InvProduct.IsOnHold = 0 AND ProductKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + AppSharedPreferences.getString("SubsidiaryKey", "") + "' AND SourceType=46) ";
        }
        String str2 = str + " ORDER BY ID";
        Mylog.e(TAG, "getItemLookupItemCodeData Query = " + str2);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str2);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.2
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemLookupItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemLookupItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getItemDataForGoodsReturn() {
        String str = "SELECT TOP 1000 InvProduct.ID, InvProduct.BasePrice,InvProduct.Description,InvProduct.AllowFractionalQuantity,InvInventoryItem.AvailableQuantity InStockQuantity, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage,InvProduct.UOMGroupKey, InvUOM.Id UOMId FROM InvProduct WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup ON InvProduct.UOMGroupKey = InvUOMGroup.UOMGroupKey LEFT OUTER JOIN InvUOM ON InvUOMGroup.BaseUOMKey = InvUOM.UOMKey LEFT OUTER JOIN InvInventoryItem ON InvProduct.ProductKey = InvInventoryItem.ProductKey AND InvInventoryItem.WarehouseKey = '" + ((SiteBean) new Gson().fromJson(AppPreferences.getSiteDetails(), SiteBean.class)).getWarehouseKey() + "' WHERE InvProduct.IsNonStock=0 AND InvProduct.IsDeleted=0 AND InvProduct.IsGiftCertificate=0 AND InvProduct.IsMatrixItem=0";
        if (AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str = str + " AND InvProduct.ProductKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + AppSharedPreferences.getString("SubsidiaryKey", "") + "' AND SourceType=46) ";
        }
        String str2 = str + " ORDER BY ID";
        Mylog.e(TAG, "getItemLookupItemCodeData Query = " + str2);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str2);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.3
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemLookupItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemLookupItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getItemCodeData(String str) {
        String str2;
        if (!AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str2 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey WHERE IsNonStock=0 AND P.IsDeleted=0 AND IsGiftCertificate=0 AND IsMatrixItem=0 AND P.IsPurchasable = 1 AND P.IsOnHold = 0";
        } else {
            str2 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey WHERE IsNonStock=0 AND P.IsDeleted=0 AND IsGiftCertificate=0 AND IsMatrixItem=0 AND P.IsPurchasable = 1 AND P.IsOnHold = 0 AND ProductKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + str + "' AND SourceType=46) ";
        }
        String str3 = str2 + " ORDER BY P.ID";
        String str4 = TAG;
        Mylog.e(str4, "getItemCodeData Query = " + str3);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str3);
        Mylog.e(str4, "getItemCodeData URL=" + queryResult.request().url());
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.4
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getItemCodeDataForVendor(boolean z, String str, String str2) {
        String str3;
        if (!z) {
            str3 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity, T.Id AS PurchaseTaxCodeId FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey LEFT OUTER JOIN TaxTaxCode T WITH (NOLOCK) ON T.TaxCodeKey = P.PurchaseTaxCodeKey ";
        } else {
            str3 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity, T.Id AS PurchaseTaxCodeId FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey LEFT OUTER JOIN TaxTaxCode T WITH (NOLOCK) ON T.TaxCodeKey = P.PurchaseTaxCodeKey  Inner Join PurVendorProduct On P.ProductKey = PurVendorProduct.ProductKey And PurVendorProduct.IsDeleted = 'FALSE' And PurVendorProduct.VendorKey = (Select VendorKey From PurVendor WHERE Id = '" + str + "')";
        }
        String str4 = str3 + " WHERE IsNonStock=0 AND P.IsDeleted=0 AND IsGiftCertificate=0 AND IsMatrixItem=0 AND P.IsPurchasable = 1 AND P.IsOnHold = 0";
        if (AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str4 = str4 + " AND P.ProductKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + str2 + "' AND SourceType=46) ";
        }
        String str5 = str4 + " ORDER BY P.ID DESC";
        String str6 = TAG;
        Mylog.e(str6, "getItemCodeDataForVendor Query = " + str5);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str5);
        Mylog.e(str6, "getItemCodeData URL=" + queryResult.request().url());
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.5
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getItemCodeDataForStockTake(String str) {
        String str2;
        if (!AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str2 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey WHERE IsNonStock=0 AND P.IsDeleted=0 AND IsGiftCertificate=0 AND IsMatrixItem=0 AND P.IsOnHold =0";
        } else {
            str2 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey WHERE IsNonStock=0 AND P.IsDeleted=0 AND IsGiftCertificate=0 AND IsMatrixItem=0 AND P.IsOnHold =0 AND ProductKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + str + "' AND SourceType=46) ";
        }
        String str3 = str2 + " ORDER BY P.ID";
        String str4 = TAG;
        Mylog.e(str4, "getItemCodeData Query = " + str3);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str3);
        Mylog.e(str4, "getItemCodeData URL=" + queryResult.request().url());
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.6
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        e.printStackTrace();
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getItemCodeDataRequest(String str) {
        String str2;
        if (AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str2 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey  Inner Join (SELECT SubSubsidiaryItem.SourceKey from SubSubsidiaryItem  Inner Join SubSubsidiaryItem T1 On T1.SourceType = 46 AND T1.SubsidiaryKey = (SELECT SubsidiaryKey FROM InvWarehouse WHERE Id = '" + str + "') And SubSubsidiaryItem.SourceKey = T1.SourceKey WHERE SubSubsidiaryItem.SourceType = 46 AND SubSubsidiaryItem.SubsidiaryKey = '" + AppPreferences.getSubsidiaryKey() + "') SubSubsidiaryItem1 On P.ProductKey = SubSubsidiaryItem1.SourceKey  AND P.IsDeleted=0 ";
        } else {
            str2 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, P.BasePrice, P.UOMGroupKey, U.Id UOMId,P.AllowFractionalQuantity AllowFractionalQuantity FROM InvProduct P WITH (NOLOCK) LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey  WHERE  P.IsDeleted=0 AND P.IsOnHold = 0";
        }
        String str3 = str2 + " ORDER BY P.ID";
        String str4 = TAG;
        Mylog.e(str4, "getItemCodeData Query = " + str3);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str3);
        Mylog.e(str4, "getItemCodeData URL=" + queryResult.request().url());
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.7
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getGRPOItemCodeData(String str) {
        String str2 = "SELECT TOP 1000 ID,InvProduct.BasePrice, InvProduct.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, (Case WHEN UOMKey= '0' THEN (Quantity-isnull(QuantityReceived,0)) ELSE (UOMQuantity-isnull(UOMQuantityReceived,0)) END) as Quantity, PurchaseOrderDetailKey, (Case WHEN UOMKey='0' THEN '' ELSE (select Id from InvUOM where InvUOM.UOMKey =PurPurchaseOrderDetail.UOMKey ) END) UOMKey, InvProduct.UOMGroupKey,InvProduct.AllowFractionalQuantity, ItemsPerUnit, (Quantity-isnull(QuantityReceived,0)) as UOMQuantity FROM PurPurchaseOrderDetail inner join InvProduct on PurPurchaseOrderDetail.ProductKey = InvProduct.ProductKey WHERE PurPurchaseOrderDetail.IsDeleted = 0 AND PurchaseOrderKey='" + str + "' AND Status=0 AND WarehouseKey='" + ((SiteBean) new Gson().fromJson(AppPreferences.getSiteDetails(), SiteBean.class)).getWarehouseKey() + "'";
        Mylog.e(TAG, "getGRPOItemCodeData ItemQuery = " + str2);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str2);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.8
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getGRPOItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getGRPOItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getSTReceiptItemCodeData(String str) {
        String str2 = "SELECT TOP 1000 ID, InvStockTransferDetail.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, (Case WHEN UOMKey= '0' THEN (Quantity-isnull(QuantityReceived,0)) ELSE (UOMQuantity-isnull(UOMQuantityReceived,0)) END) as Quantity, StockTransferDetailKey, (Case WHEN UOMKey= '0' THEN '' ELSE (select Id from InvUOM where InvUOM.UOMKey =InvStockTransferDetail.UOMKey ) END) UOMKey,InvProduct.UOMGroupKey,InvProduct.AllowFractionalQuantity, SourceKey, UOMQuantityOpen as UOMQuantity FROM InvStockTransferDetail  inner join InvProduct on InvStockTransferDetail.ProductKey = InvProduct.ProductKey WHERE StockTransferKey = '" + str + "' AND  Status = 0";
        String str3 = TAG;
        Mylog.e(str3, "getSTReceiptItemCodeData ItemQuery = " + str2);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str2);
        Mylog.e(str3, "getSTReceiptItemCodeData URL =" + queryResult.request().url());
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.9
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getSTReceiptItemCodeData onResponse code = " + response.code());
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getSTReceiptItemCodeData onResponse  = " + new Gson().toJson(response.body()));
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getSTReceiptItemCodeData Failure = " + th.getMessage());
            }
        });
    }

    public void getGRItemCodeData(String str) {
        String str2 = "SELECT TOP 1000 P.Id ,P.Description, P.BasePrice,P.AllowFractionalQuantity,(Case WHEN P.IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN P.IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, (GRD.QuantityReceived - isnull(GRD.QuantityReturned,0)) QuantityReceived, GRD.ItemsPerUnit, GRD.UOMKey, U.Id UOMId, P.UOMGroupKey, (isnull(GRD.UOMQuantityReceived,0) - isnull(GRD.UOMQuantityReturned,0)) UOMQuantityReceived, GRD.GoodsReceiptDetailKey FROM InvGoodReceiptDetail GRD (NOLOCK) inner Join InvProduct P (NOLOCK) on GRD.ProductKey = P.ProductKey LEFT OUTER JOIN InvUOM U (NOLOCK) ON GRD.UOMKey = U.UOMKey WHERE GRD.GoodsReceiptKey ='" + str + "' AND GRD.QuantityReceived-GRD.QuantityReturned >0";
        Mylog.e(TAG, "getGRItemCodeData Query = " + str2);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str2);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.10
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getGRItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                        itemCodeRetrofitListener.onItemCodeArrayReceived(null);
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                itemCodeRetrofitListener.onItemCodeArrayReceived(null);
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getGRItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getLocationTransferItemCodeData(String str) {
        String str2 = "SELECT TOP 1000 P.ID, P.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END)as ItemManage, L.InStockQuantity,P.BasePrice, P.UOMGroupKey,P.AllowFractionalQuantity AllowFractionalQuantity, U.Id UOMId FROM InvProduct P WITH (NOLOCK) INNER JOIN InvInventoryLocation L ON P.ProductKey = L.ProductKey LEFT OUTER JOIN InvUOMGroup UG WITH (NOLOCK) ON P.UOMGroupKey = UG.UOMGroupKey LEFT OUTER JOIN InvUOM U WITH (NOLOCK) ON UG.BaseUOMKey = U.UOMKey WHERE P.IsNonStock=0 AND P.IsDeleted=0 AND P.IsGiftCertificate=0 AND P.IsMatrixItem=0 AND P.IsOnHold = 0 AND L.AvailableQuantity>0 AND  L.LocationKey= '" + str + "' ORDER BY P.ID";
        Mylog.e(TAG, "getLocationTransferItemCodeData Query = " + str2);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str2);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.11
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getLocationTransferItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                        return;
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                        itemCodeRetrofitListener.onItemCodeArrayReceived(null);
                        return;
                    }
                }
                itemCodeRetrofitListener.onItemCodeArrayReceived(null);
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                itemCodeRetrofitListener.onItemCodeArrayReceived(null);
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getLocationTransferItemCodeData onFailure = " + th.getMessage());
            }
        });
    }

    public void getStorePickItemCodeData(String str) {
        String str2 = "SELECT ID, InvProduct.Description, (Case WHEN IsSerialTracked= 1 THEN '2' ELSE (CASE WHEN IsBatchTracked = 1 Then '3' Else '1' END) END) as ItemManage, (Case WHEN UOMGroupDetailKey= '0' THEN PickingQuantity ELSE UOMPickingQuantity END) as Quantity,PickingDetailKey, (Case WHEN UOMGroupDetailKey='0' THEN '' ELSE (select Id from InvUOM where InvUOM.UOMKey = (SELECT UOMKey FROM InvUOMGroupDetail WHERE UOMGroupDetailKey= InvPickingDetail.UOMGroupDetailKey)) END) UOMKey, InvProduct.UOMGroupKey,InvProduct.AllowFractionalQuantity,UOMGroupDetailKey, PickingQuantity as UOMQuantity FROM InvPickingDetail INNER JOIN InvProduct on InvProduct.ProductKey = InvPickingDetail.ProductKey WHERE InvPickingDetail.IsDeleted = 0 AND PickingKey='" + str + "' AND PickingStatus=0 ";
        Mylog.e(TAG, "getGRPOItemCodeData ItemQuery = " + str2);
        ApiInterface xMLAPIClient = ApiClient.getXMLAPIClient();
        this.apiInterface = xMLAPIClient;
        Call<String> queryResult = xMLAPIClient.getQueryResult(str2);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.12
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                ItemCodeRetrofitListener itemCodeRetrofitListener = (ItemCodeRetrofitListener) ItemCodeRetrofitHandler.this.mWeakListener.get();
                if (itemCodeRetrofitListener == null) {
                    return;
                }
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getGRPOItemCodeData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        ItemCodeXMLHandler itemCodeXMLHandler = new ItemCodeXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, itemCodeXMLHandler);
                        itemCodeRetrofitListener.onItemCodeArrayReceived(itemCodeXMLHandler.getSearchTransactionsResponseList());
                    } catch (Exception e) {
                        Mylog.e(ItemCodeRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemCodeRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemCodeRetrofitHandler.TAG, "getGRPOItemCodeData onFailure = " + th.getMessage());
            }
        });
    }
}
