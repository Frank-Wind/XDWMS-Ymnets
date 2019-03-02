//------------------------------------------------------------------------------
// <auto-generated>
//     此代码已从模板生成。
//
//     手动更改此文件可能导致应用程序出现意外的行为。
//     如果重新生成代码，将覆盖对此文件的手动更改。
// </auto-generated>
//------------------------------------------------------------------------------

namespace Apps.Models
{
    using System;
    using System.Collections.Generic;
    
    public partial class WMS_Part
    {
        public WMS_Part()
        {
            this.WMS_AI = new HashSet<WMS_AI>();
            this.WMS_Feed_List = new HashSet<WMS_Feed_List>();
            this.WMS_Feed_List1 = new HashSet<WMS_Feed_List>();
            this.WMS_Inv_Adjust = new HashSet<WMS_Inv_Adjust>();
            this.WMS_PO = new HashSet<WMS_PO>();
            this.WMS_Product_Entry = new HashSet<WMS_Product_Entry>();
            this.WMS_Sale_Order = new HashSet<WMS_Sale_Order>();
            this.WMS_Inventory_D = new HashSet<WMS_Inventory_D>();
            this.WMS_ReturnOrder = new HashSet<WMS_ReturnOrder>();
            this.WMS_Inv_History_D = new HashSet<WMS_Inv_History_D>();
            this.WMS_Inv = new HashSet<WMS_Inv>();
        }
    
        public int Id { get; set; }
        public string PartCode { get; set; }
        public string PartName { get; set; }
        public string PartType { get; set; }
        public string CustomerCode { get; set; }
        public string LogisticsCode { get; set; }
        public string OtherCode { get; set; }
        public Nullable<decimal> PCS { get; set; }
        public string StoreMan { get; set; }
        public string Status { get; set; }
        public string CreatePerson { get; set; }
        public Nullable<System.DateTime> CreateTime { get; set; }
        public string ModifyPerson { get; set; }
        public Nullable<System.DateTime> ModifyTime { get; set; }
        public string Unit { get; set; }
        public Nullable<decimal> Volume { get; set; }
        public string Remark { get; set; }
    
        public virtual ICollection<WMS_AI> WMS_AI { get; set; }
        public virtual ICollection<WMS_Feed_List> WMS_Feed_List { get; set; }
        public virtual ICollection<WMS_Feed_List> WMS_Feed_List1 { get; set; }
        public virtual ICollection<WMS_Inv_Adjust> WMS_Inv_Adjust { get; set; }
        public virtual ICollection<WMS_PO> WMS_PO { get; set; }
        public virtual ICollection<WMS_Product_Entry> WMS_Product_Entry { get; set; }
        public virtual ICollection<WMS_Sale_Order> WMS_Sale_Order { get; set; }
        public virtual ICollection<WMS_Inventory_D> WMS_Inventory_D { get; set; }
        public virtual ICollection<WMS_ReturnOrder> WMS_ReturnOrder { get; set; }
        public virtual ICollection<WMS_Inv_History_D> WMS_Inv_History_D { get; set; }
        public virtual ICollection<WMS_Inv> WMS_Inv { get; set; }
    }
}
