package com.citixsys.ivend_handheld.itemLookUp;

import com.citixsys.ivend_handheld.R;
import com.citixsys.ivend_handheld.base.BaseActivity;
import com.citixsys.ivend_handheld.base.BaseRetrofitHandler;
import com.citixsys.ivend_handheld.log.Mylog;
import com.citixsys.ivend_handheld.retrofit.ApiClient;
import com.citixsys.ivend_handheld.utils.AndroidUtils;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/* JADX INFO: loaded from: classes.dex */
public class ItemLookupPrintLabelRetrofitHandler extends BaseRetrofitHandler {
    private static final String TAG = "com.citixsys.ivend_handheld.itemLookUp.ItemLookupPrintLabelRetrofitHandler";
    private WeakReference<printLabelRetrofitListener> mWeakListener;

    public interface printLabelRetrofitListener {
        void onPrintLabelDataReceived(String str);
    }

    public ItemLookupPrintLabelRetrofitHandler(BaseActivity baseActivity) {
        super(baseActivity);
    }

    public void registerInitializationListener(printLabelRetrofitListener printlabelretrofitlistener) {
        this.mWeakListener = new WeakReference<>(printlabelretrofitlistener);
    }

    public void sendDataToPrintItemLabel(ArrayList<PrintItemLabelsRequest> arrayList) {
        Call<ResponseBody> callSendPrintItemLabelsData = ApiClient.getXMLAPIClient().sendPrintItemLabelsData(arrayList);
        Mylog.e(TAG, " URL=" + callSendPrintItemLabelsData.request().url());
        startProgressDialog(AndroidUtils.getResourceString(R.string.Common_Loading));
        callSendPrintItemLabelsData.enqueue(new Callback() { // from class: com.citixsys.ivend_handheld.itemLookUp.ItemLookupPrintLabelRetrofitHandler.1
            @Override // retrofit2.Callback
            public void onResponse(Call call, Response response) {
                ItemLookupPrintLabelRetrofitHandler.this.endProgressDialog();
                printLabelRetrofitListener printlabelretrofitlistener = (printLabelRetrofitListener) ItemLookupPrintLabelRetrofitHandler.this.mWeakListener.get();
                if (printlabelretrofitlistener == null) {
                    return;
                }
                Mylog.e(ItemLookupPrintLabelRetrofitHandler.TAG, "onResponse==   " + response.code());
                if (response.code() == 200) {
                    printlabelretrofitlistener.onPrintLabelDataReceived("");
                }
            }

            @Override // retrofit2.Callback
            public void onFailure(Call call, Throwable th) {
                ItemLookupPrintLabelRetrofitHandler.this.endProgressDialog();
                Mylog.e(ItemLookupPrintLabelRetrofitHandler.TAG, "onFailure=  " + th.getMessage());
                ItemLookupPrintLabelRetrofitHandler.this.showAlert(R.string.ItemLookup_Alert, R.string.Error_NotAbleToPrint);
            }
        });
    }
}
