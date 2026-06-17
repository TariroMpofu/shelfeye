package com.citixsys.ivend_handheld.utility.commonRetrofit;

import android.util.Xml;
import com.citixsys.ivend_handheld.R;
import com.citixsys.ivend_handheld.base.BaseActivity;
import com.citixsys.ivend_handheld.base.BaseRetrofitHandler;
import com.citixsys.ivend_handheld.log.Mylog;
import com.citixsys.ivend_handheld.retrofit.ApiClient;
import com.citixsys.ivend_handheld.utility.CommonMethods;
import com.citixsys.ivend_handheld.utility.commonDataModel.CustomerBean;
import com.citixsys.ivend_handheld.utility.commonXmlParser.CustomerXMLHandler;
import com.citixsys.ivend_handheld.utils.AndroidUtils;
import com.citixsys.ivend_handheld.utils.AppSharedPreferences;
import com.citixsys.ivend_handheld.utils.CommonUtils;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/* JADX INFO: loaded from: classes.dex */
public class CustomerRetrofitHandler extends BaseRetrofitHandler {
    private static final String TAG = CustomerRetrofitListener.class.getName();
    private WeakReference<CustomerRetrofitListener> mWeakListener;

    public interface CustomerRetrofitListener {
        void onCustomerListReceived(List<CustomerBean> list);
    }

    public CustomerRetrofitHandler(BaseActivity baseActivity) {
        super(baseActivity);
    }

    public void registerInitializationListener(CustomerRetrofitListener customerRetrofitListener) {
        this.mWeakListener = new WeakReference<>(customerRetrofitListener);
    }

    public void getCustomerData() {
        String str;
        if (!AppSharedPreferences.getBoolean("HasBranchSetup", false)) {
            str = "SELECT Id, (isnull(FirstName, '') + ' ' + isnull(LastName, '')) as Name FROM CusCustomer WITH (NOLOCK) WHERE IsDeleted=0";
        } else {
            str = "SELECT Id, (isnull(FirstName, '') + ' ' + isnull(LastName, '')) as Name FROM CusCustomer WITH (NOLOCK) WHERE IsDeleted=0 AND CustomerKey IN (SELECT CustomerKey FROM CusCustomerBranch WITH (NOLOCK) WHERE BranchKey=N'" + AppSharedPreferences.getString("selectedWarehouseBranchCode", "") + "' and IsDeleted=0)";
        }
        if (AppSharedPreferences.getBoolean("IsSubsidiaryEnabled", false)) {
            str = str + " AND CustomerKey IN (SELECT SourceKey FROM SubSubsidiaryItem WITH (NOLOCK) WHERE SubsidiaryKey = '" + AppSharedPreferences.getString("SubsidiaryKey", "") + "' AND SourceType=20)";
        }
        String str2 = str + " ORDER BY CompanyName";
        Mylog.e(TAG, "getCustomerData Query = " + str2);
        Call<String> queryResult = ApiClient.getXMLAPIClient().getQueryResult(str2);
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        queryResult.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.utility.commonRetrofit.CustomerRetrofitHandler.1
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                CustomerRetrofitHandler.this.endProgressDialog();
                CustomerRetrofitListener customerRetrofitListener = (CustomerRetrofitListener) CustomerRetrofitHandler.this.mWeakListener.get();
                if (customerRetrofitListener == null) {
                    return;
                }
                Mylog.e(CustomerRetrofitHandler.TAG, "getCustomerData onResponse = " + response.code());
                if (response.code() == 200) {
                    try {
                        String strReplaceTextForSAXParser = CommonMethods.replaceTextForSAXParser((String) response.body());
                        CustomerXMLHandler customerXMLHandler = new CustomerXMLHandler();
                        Xml.parse(strReplaceTextForSAXParser, customerXMLHandler);
                        ArrayList<CustomerBean> searchTransactionsResponseList = customerXMLHandler.getSearchTransactionsResponseList();
                        if (CommonUtils.isListEmptyOrNull(searchTransactionsResponseList)) {
                            return;
                        }
                        Mylog.e(CustomerRetrofitHandler.TAG, "getCustomerData Customer Size=" + searchTransactionsResponseList.size());
                        customerRetrofitListener.onCustomerListReceived(searchTransactionsResponseList);
                    } catch (Exception e) {
                        Mylog.e(CustomerRetrofitHandler.TAG, "Exception = " + e.getLocalizedMessage());
                    }
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                CustomerRetrofitHandler.this.endProgressDialog();
                Mylog.e(CustomerRetrofitHandler.TAG, "getCustomerData onFailure=  " + th.getMessage());
            }
        });
    }
}
