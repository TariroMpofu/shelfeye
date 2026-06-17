package com.citixsys.ivend_handheld.itemLookUp;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.widget.Toolbar;
import androidx.core.content.ContextCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.DefaultItemAnimator;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.citixsys.ivend_handheld.R;
import com.citixsys.ivend_handheld.appBase.Drawer.BaseDrawer;
import com.citixsys.ivend_handheld.base.ScanBaseActivity;
import com.citixsys.ivend_handheld.itemLookUp.ItemLookupPrintLabelRetrofitHandler;
import com.citixsys.ivend_handheld.listener.RecyclerViewClickListener;
import com.citixsys.ivend_handheld.log.Mylog;
import com.citixsys.ivend_handheld.login.SiteBean;
import com.citixsys.ivend_handheld.socketScanner.HandHeldApplication;
import com.citixsys.ivend_handheld.utility.CommonMethods;
import com.citixsys.ivend_handheld.utility.commonAdapter.CustomerListAdapter;
import com.citixsys.ivend_handheld.utility.commonDataModel.CustomerBean;
import com.citixsys.ivend_handheld.utility.commonDataModel.ItemCodeBean;
import com.citixsys.ivend_handheld.utility.commonDataModel.ItemPrice;
import com.citixsys.ivend_handheld.utility.commonDataModel.ProductDetails;
import com.citixsys.ivend_handheld.utility.commonDataModel.ProductDetailsBean;
import com.citixsys.ivend_handheld.utility.commonRetrofit.CustomerRetrofitHandler;
import com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler;
import com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler;
import com.citixsys.ivend_handheld.utils.AlertUtils;
import com.citixsys.ivend_handheld.utils.AndroidUtils;
import com.citixsys.ivend_handheld.utils.AppPreferences;
import com.citixsys.ivend_handheld.utils.AppSharedPreferences;
import com.citixsys.ivend_handheld.utils.CommonUtils;
import com.citixsys.ivend_handheld.utils.StringUtils;
import com.google.android.material.navigation.NavigationView;
import com.google.gson.Gson;
import com.google.zxing.integration.android.IntentIntegrator;
import com.google.zxing.integration.android.IntentResult;
import java.util.ArrayList;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public class ItemLookupActivity extends ScanBaseActivity implements View.OnClickListener, ItemCodeRetrofitHandler.ItemCodeRetrofitListener, ProductRetrofitHandler.ProductRetrofitListener, RecyclerViewClickListener, CustomerRetrofitHandler.CustomerRetrofitListener, ItemLookupPrintLabelRetrofitHandler.printLabelRetrofitListener {
    private static final String TAG = "com.citixsys.ivend_handheld.itemLookUp.ItemLookupActivity";
    private Button clearBtn;
    private EditText customerId;
    private List<CustomerBean> customerList;
    private EditText descriptionEdT;
    private EditText invEdT;
    private boolean isSocketScannerReadValue;
    private EditText itemCodeEdTxt;
    private List<ItemCodeBean> itemCodeList;
    private EditText poIdEdTxt;
    private EditText priceEdT;
    private Button printLabel;
    private ImageView searchPOId;
    private String selectedCustomerId;
    private String selectedProductId;
    private String selectedUomId = "";

    @Override // com.citixsys.ivend_handheld.base.ScanBaseActivity, com.citixsys.ivend_handheld.base.BaseActivity, androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        CommonMethods.forceRTLIfSupported(this);
        setContentView(R.layout.itemlookupnscreen);
        initToolbar();
        initializeUI();
        getItemCodeData();
    }

    private void initToolbar() {
        String string = getIntent().getExtras().getString("Title");
        Toolbar toolbar = (Toolbar) findViewById(R.id.customer_edit_toolbar);
        ((TextView) findViewById(R.id.toolbar_title_txt)).setText(string);
        ImageButton imageButton = (ImageButton) findViewById(R.id.saveButton);
        imageButton.setVisibility(4);
        imageButton.setOnClickListener(this);
        ((ImageButton) findViewById(R.id.backButton)).setVisibility(4);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayShowTitleEnabled(false);
        DrawerLayout drawerLayout = (DrawerLayout) findViewById(R.id.drawer_layout);
        NavigationView navigationView = (NavigationView) findViewById(R.id.nvView);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setHomeButtonEnabled(true);
        getSupportActionBar().setHomeAsUpIndicator(ContextCompat.getDrawable(this, R.drawable.zy_hamburger_selector));
        new BaseDrawer(navigationView, drawerLayout, this, null).setupDrawerContent(toolbar);
    }

    private void initializeUI() {
        this.poIdEdTxt = (EditText) findViewById(R.id.et_itemlookuppoid);
        this.customerId = (EditText) findViewById(R.id.et_customerId);
        this.itemCodeEdTxt = (EditText) findViewById(R.id.et_itemlookupIC);
        this.descriptionEdT = (EditText) findViewById(R.id.et_itemlookupDes);
        ImageButton imageButton = (ImageButton) findViewById(R.id.itemlookupICscan);
        this.invEdT = (EditText) findViewById(R.id.et_itemlookupINV);
        this.priceEdT = (EditText) findViewById(R.id.et_itemlookupPrice);
        this.searchPOId = (ImageView) findViewById(R.id.itemlookupSearch);
        ImageView imageView = (ImageView) findViewById(R.id.customerSearch);
        this.printLabel = (Button) findViewById(R.id.btn_printlabel);
        this.clearBtn = (Button) findViewById(R.id.clear_btn);
        TextView textView = (TextView) findViewById(R.id.item_lookup_price_txt);
        this.clearBtn.setOnClickListener(this);
        this.printLabel.setOnClickListener(this);
        this.searchPOId.setOnClickListener(this);
        imageView.setOnClickListener(this);
        this.poIdEdTxt.setOnFocusChangeListener(new View.OnFocusChangeListener() { // from class: com.citixsys.ivend_handheld.itemLookUp.ItemLookupActivity.1
            @Override // android.view.View.OnFocusChangeListener
            public void onFocusChange(View view, boolean z) {
                if (z) {
                    return;
                }
                ItemLookupActivity itemLookupActivity = ItemLookupActivity.this;
                itemLookupActivity.validateBarcode(itemLookupActivity.poIdEdTxt.getText().toString().trim());
            }
        });
        imageButton.setOnClickListener(this);
        textView.setText(getString(R.string.Po_Price) + " (" + HandHeldApplication.getSingletonObject().getCurrencySymbol() + ")");
        StringBuilder sb = new StringBuilder();
        sb.append(AppSharedPreferences.getString("CustomerId", ""));
        sb.append("-");
        sb.append(AppSharedPreferences.getString("CustomerName", ""));
        String string = sb.toString();
        this.selectedCustomerId = AppSharedPreferences.getString("CustomerId", "");
        this.customerId.setText(string);
        this.itemCodeEdTxt.requestFocus();
    }

    private void getCustomerList() {
        CustomerRetrofitHandler customerRetrofitHandler = new CustomerRetrofitHandler(this);
        customerRetrofitHandler.registerInitializationListener(this);
        customerRetrofitHandler.getCustomerData();
    }

    private void getItemCodeData() {
        ItemCodeRetrofitHandler itemCodeRetrofitHandler = new ItemCodeRetrofitHandler(this);
        itemCodeRetrofitHandler.registerInitializationListener(this);
        itemCodeRetrofitHandler.getItemLookUpData();
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void validateBarcode(String str) {
        try {
            AndroidUtils.hideKeyBoard(this.searchPOId);
            ProductRetrofitHandler productRetrofitHandler = new ProductRetrofitHandler(this);
            productRetrofitHandler.registerInitializationListener(this);
            productRetrofitHandler.getBarcodeInfo(str, 1010);
        } catch (Exception e) {
            Mylog.e(TAG, "validateBarcode Error = " + e.getLocalizedMessage());
        }
    }

    private void clearData() {
        this.poIdEdTxt.setText("");
        this.itemCodeEdTxt.setText("");
        this.descriptionEdT.setText("");
        this.invEdT.setText("");
        this.priceEdT.setText("");
        this.poIdEdTxt.requestFocus();
        this.customerId.clearFocus();
    }

    @Override // androidx.activity.ComponentActivity, android.app.Activity
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }

    @Override // android.view.View.OnClickListener
    public void onClick(View view) {
        if (view.getId() == R.id.btn_printlabel) {
            showPrintLabelDialog();
            return;
        }
        if (view.getId() == R.id.backButton) {
            onBackPressed();
            return;
        }
        if (view.getId() == R.id.dummyToolbarBackButton) {
            dismissCustomAlert();
            return;
        }
        if (view.getId() == R.id.itemlookupSearch) {
            AndroidUtils.hideKeyBoard(this.searchPOId);
            showItemCodeListDialog();
        } else if (view.getId() == R.id.customerSearch) {
            getCustomerList();
        } else if (view.getId() == R.id.itemlookupICscan) {
            onItemCameraBtnClick();
        } else if (view.getId() == R.id.clear_btn) {
            onClearBtnClick();
        }
    }

    private void onClearBtnClick() {
        clearData();
    }

    private void onItemCameraBtnClick() {
        if (ContextCompat.checkSelfPermission(this, "android.permission.CAMERA") != 0) {
            checkCameraPermission();
        } else {
            CommonUtils.startCaptureActivityForScan(this);
        }
    }

    private void showItemCodeListDialog() {
        if (CommonUtils.isListEmptyOrNull(this.itemCodeList)) {
            return;
        }
        ItemListRecyclerViewAdapter itemListRecyclerViewAdapter = new ItemListRecyclerViewAdapter(this.itemCodeList);
        itemListRecyclerViewAdapter.registerRecyclerViewListener(this);
        setAlertDialog(AlertUtils.showItemSelectionAlert(this, itemListRecyclerViewAdapter, this));
    }

    private void showCustomerListDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View viewInflate = getLayoutInflater().inflate(R.layout.customerlistdialog, (ViewGroup) null);
        builder.setView(viewInflate);
        ((TextView) viewInflate.findViewById(R.id.toolbar_title_txt)).setText(AndroidUtils.getResourceString(R.string.Customer_Select));
        RecyclerView recyclerView = (RecyclerView) viewInflate.findViewById(R.id.lv_multi);
        viewInflate.findViewById(R.id.dummyToolbarBackButton).setOnClickListener(this);
        recyclerView.setAdapter(new CustomerListAdapter(this, this.customerList, this));
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setItemAnimator(new DefaultItemAnimator());
        setAlertDialog(builder.show());
    }

    @Override // com.citixsys.ivend_handheld.listener.RecyclerViewClickListener
    public void recyclerViewListClicked(View view, int i) {
        if (view.getId() == R.id.ll_ILookupcontainer) {
            onItemRecyclerDataReceived(i);
        } else if (view.getId() == R.id.ll_CustomerListcontainer) {
            onCustomerRecyclerDataReceived(i);
        }
        dismissCustomAlert();
    }

    private void onCustomerRecyclerDataReceived(int i) {
        this.selectedCustomerId = this.customerList.get(i).getId();
        this.customerId.setText(this.selectedCustomerId + "-" + this.customerList.get(i).getName());
        String str = this.selectedProductId;
        if (str == null || str.equals("")) {
            return;
        }
        getSpecialPriceList();
    }

    private void onItemRecyclerDataReceived(int i) {
        List<ItemCodeBean> list = this.itemCodeList;
        if (list != null) {
            String id = list.get(i).getId();
            Mylog.e("recyclerViewListClicked", id);
            this.poIdEdTxt.setText(id);
            validateBarcode(this.poIdEdTxt.getText().toString().trim());
        }
    }

    @Override // com.citixsys.ivend_handheld.utility.commonRetrofit.ItemCodeRetrofitHandler.ItemCodeRetrofitListener
    public void onItemCodeArrayReceived(List<ItemCodeBean> list) {
        this.itemCodeList = list;
    }

    @Override // com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.ProductRetrofitListener
    public void onProductReceived(ProductDetails productDetails) {
        if (productDetails.getMessage().equals("")) {
            String id = productDetails.getId();
            this.selectedProductId = id;
            this.selectedUomId = "";
            this.poIdEdTxt.setText(id);
            this.itemCodeEdTxt.setText(productDetails.getId());
            this.descriptionEdT.setText(productDetails.getDescription());
            for (int i = 0; i < productDetails.getProductInventoryList().size(); i++) {
                if (productDetails.getProductInventoryList().get(i).getWarehouseId().equalsIgnoreCase(AppSharedPreferences.getString("selectedWarehouseId", ""))) {
                    double dDoubleValue = productDetails.getProductInventoryList().get(i).getInStockQuantity().doubleValue();
                    this.invEdT.setText("" + dDoubleValue);
                    this.priceEdT.setText("" + productDetails.getProductInventoryList().get(i).getPrice());
                }
            }
            this.printLabel.setVisibility(0);
            this.clearBtn.setVisibility(0);
            getSpecialPriceList();
        }
    }

    private void getSpecialPriceList() {
        SiteBean siteBean = (SiteBean) new Gson().fromJson(AppPreferences.getSiteDetails(), SiteBean.class);
        ProductRetrofitHandler productRetrofitHandler = new ProductRetrofitHandler(this);
        productRetrofitHandler.registerInitializationListener(this);
        productRetrofitHandler.getItemSalesPrice(this.selectedProductId, this.selectedCustomerId, siteBean.getStoreId(), this.selectedUomId, 0.0d);
    }

    @Override // com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.ProductRetrofitListener
    public void onItemPriceReceived(ItemPrice itemPrice) {
        if (itemPrice.getItemPrice().doubleValue() != 0.0d) {
            this.priceEdT.setText(String.valueOf(itemPrice.getItemPrice()));
        }
    }

    @Override // com.citixsys.ivend_handheld.utility.commonRetrofit.ProductRetrofitHandler.ProductRetrofitListener
    public void onBarcodeInfoReceived(ProductDetailsBean productDetailsBean, boolean z) {
        if (!z) {
            showAlert(R.string.ItemLookup_Alert, R.string.Invalid_POid);
            return;
        }
        this.poIdEdTxt.setText(productDetailsBean.getId());
        this.itemCodeEdTxt.setText(productDetailsBean.getId());
        productDetailsBean.getPrice();
        ProductRetrofitHandler productRetrofitHandler = new ProductRetrofitHandler(this);
        productRetrofitHandler.registerInitializationListener(this);
        productRetrofitHandler.getProductDetails(productDetailsBean.getId());
    }

    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, android.app.Activity
    protected void onActivityResult(int i, int i2, Intent intent) {
        if (i == 49374 && intent == null) {
            return;
        }
        IntentResult activityResult = IntentIntegrator.parseActivityResult(i, i2, intent);
        if (activityResult != null) {
            if (activityResult.getContents() == null) {
                Toast.makeText(this, "Result Not Found", 1).show();
                return;
            }
            try {
                validateBarcode(activityResult.getContents());
                return;
            } catch (Exception e) {
                Mylog.e(TAG, "Exception = " + e.getLocalizedMessage());
                Toast.makeText(this, activityResult.getContents(), 1).show();
                return;
            }
        }
        super.onActivityResult(i, i2, intent);
    }

    @Override // com.citixsys.ivend_handheld.base.ScanBaseActivity, androidx.fragment.app.FragmentActivity, android.app.Activity
    protected void onResume() {
        super.onResume();
        this.isSocketScannerReadValue = true;
    }

    @Override // com.citixsys.ivend_handheld.base.ScanBaseActivity, com.citixsys.ivend_handheld.base.BaseActivity, androidx.fragment.app.FragmentActivity, android.app.Activity
    protected void onPause() {
        super.onPause();
        this.isSocketScannerReadValue = false;
    }

    @Override // com.citixsys.ivend_handheld.base.BaseActivity, androidx.appcompat.app.AppCompatActivity, androidx.fragment.app.FragmentActivity, android.app.Activity
    protected void onDestroy() {
        super.onDestroy();
    }

    @Override // com.citixsys.ivend_handheld.base.ScanBaseActivity, com.citixsys.ivend_handheld.socketScanner.OnSocketDataArrivalListener
    public void onDataArrived(char[] cArr) {
        String strTrim = new String(cArr).trim();
        Mylog.e("GoodsReceipt", "id ==" + strTrim);
        if (this.isSocketScannerReadValue) {
            validateBarcode(strTrim);
        }
    }

    @Override // com.citixsys.ivend_handheld.utility.commonRetrofit.CustomerRetrofitHandler.CustomerRetrofitListener
    public void onCustomerListReceived(List<CustomerBean> list) {
        this.customerList = list;
        showCustomerListDialog();
    }

    @Override // com.citixsys.ivend_handheld.itemLookUp.ItemLookupPrintLabelRetrofitHandler.printLabelRetrofitListener
    public void onPrintLabelDataReceived(String str) {
        showAlert(R.string.Common_Alert, R.string.PrintLabel_CommandSend);
        dismissCustomAlert();
    }

    @Override // com.citixsys.ivend_handheld.base.ScanBaseActivity, com.citixsys.ivend_handheld.base.MotorolaScannerHandler.DataReceivedListener
    public void onDataReceived(char[] cArr) {
        onDataArrived(cArr);
    }

    private void showPrintLabelDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View viewInflate = getLayoutInflater().inflate(R.layout.printlabelitemlookup, (ViewGroup) null);
        builder.setView(viewInflate);
        builder.setCancelable(false);
        ((TextView) viewInflate.findViewById(R.id.toolbar_title_txt)).setText(AndroidUtils.getResourceString(R.string.Common_PrintLabel));
        viewInflate.findViewById(R.id.dummyToolbarBackButton).setOnClickListener(this);
        ((EditText) viewInflate.findViewById(R.id.et_itemlookupIC)).setText(this.itemCodeEdTxt.getText().toString());
        ((EditText) viewInflate.findViewById(R.id.et_itemlookupDes)).setText(this.descriptionEdT.getText().toString());
        final EditText editText = (EditText) viewInflate.findViewById(R.id.et_itemlookupqty);
        editText.setText(this.invEdT.getText().toString());
        final EditText editText2 = (EditText) viewInflate.findViewById(R.id.et_itemlookupPrice);
        editText2.setText(this.priceEdT.getText().toString());
        ((TextView) viewInflate.findViewById(R.id.print_label_price_txt)).setText(getString(R.string.Po_Price) + " (" + HandHeldApplication.getSingletonObject().getCurrencySymbol() + ")");
        viewInflate.findViewById(R.id.btn_print).setOnClickListener(new View.OnClickListener() { // from class: com.citixsys.ivend_handheld.itemLookUp.ItemLookupActivity.2
            @Override // android.view.View.OnClickListener
            public void onClick(View view) {
                if (!StringUtils.isInvalidValue(editText.getText().toString().trim()) && Double.parseDouble(editText.getText().toString()) != 0.0d) {
                    ArrayList<PrintItemLabelsRequest> arrayList = new ArrayList<>();
                    PrintItemLabelsRequest printItemLabelsRequest = new PrintItemLabelsRequest();
                    printItemLabelsRequest.setProductId(ItemLookupActivity.this.itemCodeEdTxt.getText().toString());
                    printItemLabelsRequest.setWarehouseId(AppSharedPreferences.getString("selectedWarehouseId", ""));
                    printItemLabelsRequest.setHandheldDeviceId(AppSharedPreferences.getString("deviceId", ""));
                    if (!StringUtils.isInvalidValue(editText2.getText().toString().trim())) {
                        printItemLabelsRequest.setPrice(Double.parseDouble(editText2.getText().toString()));
                    } else {
                        printItemLabelsRequest.setPrice(0.0d);
                    }
                    printItemLabelsRequest.setQuantityToPrint(Double.parseDouble(editText.getText().toString()));
                    arrayList.add(printItemLabelsRequest);
                    ItemLookupPrintLabelRetrofitHandler itemLookupPrintLabelRetrofitHandler = new ItemLookupPrintLabelRetrofitHandler(ItemLookupActivity.this);
                    itemLookupPrintLabelRetrofitHandler.registerInitializationListener(ItemLookupActivity.this);
                    itemLookupPrintLabelRetrofitHandler.sendDataToPrintItemLabel(arrayList);
                    return;
                }
                ItemLookupActivity.this.showAlert(R.string.ItemLookup_Alert, R.string.Error_EnterQtyToPrint);
            }
        });
        setAlertDialog(builder.show());
    }
}
