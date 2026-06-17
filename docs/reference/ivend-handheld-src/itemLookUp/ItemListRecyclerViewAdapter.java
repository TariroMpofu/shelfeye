package com.citixsys.ivend_handheld.itemLookUp;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import com.citixsys.ivend_handheld.R;
import com.citixsys.ivend_handheld.listener.RecyclerViewClickListener;
import com.citixsys.ivend_handheld.listener.ViewHolderClickListener;
import com.citixsys.ivend_handheld.purchaseOrder.ItemRecyclerAdapter;
import com.citixsys.ivend_handheld.utility.commonDataModel.ItemCodeBean;
import com.citixsys.ivend_handheld.utils.CommonUtils;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public class ItemListRecyclerViewAdapter extends ItemRecyclerAdapter<ItemLookupViewHolder> implements ViewHolderClickListener {
    private ArrayList<ItemCodeBean> duplicateItemList;
    private List<ItemCodeBean> itemCodeList;
    private WeakReference<RecyclerViewClickListener> mWeakListener;

    public ItemListRecyclerViewAdapter(List<ItemCodeBean> list) {
        this.itemCodeList = list;
        ArrayList<ItemCodeBean> arrayList = new ArrayList<>();
        this.duplicateItemList = arrayList;
        arrayList.addAll(list);
    }

    public void registerRecyclerViewListener(RecyclerViewClickListener recyclerViewClickListener) {
        this.mWeakListener = new WeakReference<>(recyclerViewClickListener);
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public int getItemCount() {
        return CommonUtils.getCount(this.duplicateItemList);
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public ItemLookupViewHolder onCreateViewHolder(ViewGroup viewGroup, int i) {
        ItemLookupViewHolder itemLookupViewHolder = new ItemLookupViewHolder(LayoutInflater.from(viewGroup.getContext()).inflate(R.layout.itemcode4itemlookuplist_item, viewGroup, false));
        itemLookupViewHolder.registerViewHolderListener(this);
        return itemLookupViewHolder;
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public void onBindViewHolder(ItemLookupViewHolder itemLookupViewHolder, int i) {
        itemLookupViewHolder.getItemCode().setText(this.duplicateItemList.get(i).getId());
        itemLookupViewHolder.getDescription().setText(this.duplicateItemList.get(i).getDescription());
    }

    @Override // com.citixsys.ivend_handheld.purchaseOrder.ItemRecyclerAdapter
    public void searchItem(String str) {
        this.duplicateItemList = CommonUtils.getFilteredArray(this.itemCodeList, str);
        notifyDataSetChanged();
    }

    @Override // com.citixsys.ivend_handheld.listener.ViewHolderClickListener
    public void onItemClick(View view, int i) {
        RecyclerViewClickListener recyclerViewClickListener = this.mWeakListener.get();
        if (recyclerViewClickListener == null) {
            return;
        }
        view.setBackgroundResource(R.color.pressedList);
        recyclerViewClickListener.recyclerViewListClicked(view, CommonUtils.getItemPositionOnList(this.itemCodeList, this.duplicateItemList.get(i).getId(), this.duplicateItemList.get(i).getUomid()));
    }
}
