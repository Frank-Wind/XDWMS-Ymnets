//------------------------------------------------------------------------------
// <auto-generated>
//     此代码已从模板生成。
//
//     手动更改此文件可能导致应用程序出现意外的行为。
//     如果重新生成代码，将覆盖对此文件的手动更改。
// </auto-generated>
//------------------------------------------------------------------------------

using Apps.Models;
using System;
using System.ComponentModel.DataAnnotations;
namespace Apps.Models.WMS
{

	public partial class WMS_PartModel:Virtual_WMS_PartModel
	{
		
	}
	public class Virtual_WMS_PartModel
	{
		[Display(Name = "物料ID")]
		public virtual int Id { get; set; }
		[Display(Name = "物料编码")]
		public virtual string PartCode { get; set; }
		[Display(Name = "物料名称")]
		public virtual string PartName { get; set; }
		[Display(Name = "物料类型")]
		public virtual string PartType { get; set; }
		[Display(Name = "客户编码")]
		public virtual string CustomerCode { get; set; }
		[Display(Name = "物流号")]
		public virtual string LogisticsCode { get; set; }
		[Display(Name = "额外信息编码")]
		public virtual string OtherCode { get; set; }
		[Display(Name = "每箱数量")]
		public virtual Nullable<decimal> PCS { get; set; }
		[Display(Name = "保管员")]
		public virtual string StoreMan { get; set; }
		[Display(Name = "物料状态")]
		public virtual string Status { get; set; }
		[Display(Name = "创建人")]
		public virtual string CreatePerson { get; set; }
		[Display(Name = "创建时间")]
		public virtual Nullable<System.DateTime> CreateTime { get; set; }
		[Display(Name = "修改人")]
		public virtual string ModifyPerson { get; set; }
		[Display(Name = "修改时间")]
		public virtual Nullable<System.DateTime> ModifyTime { get; set; }
		[Display(Name = "未设置")]
		public virtual string Unit { get; set; }
		[Display(Name = "未设置")]
		public virtual Nullable<decimal> Volume { get; set; }
		[Display(Name = "未设置")]
		public virtual string Remark { get; set; }
		}
}
