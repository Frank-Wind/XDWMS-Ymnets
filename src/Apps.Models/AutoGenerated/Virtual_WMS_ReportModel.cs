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

	public partial class WMS_ReportModel:Virtual_WMS_ReportModel
	{
		
	}
	public class Virtual_WMS_ReportModel
	{
		[Display(Name = "未设置")]
		public virtual int Id { get; set; }
		[Display(Name = "报表编码")]
		public virtual string ReportCode { get; set; }
		[Display(Name = "报表名称")]
		public virtual string ReportName { get; set; }
		[Display(Name = "报表类型：1-单据，2-报表")]
		public virtual Nullable<int> ReportType { get; set; }
		[Display(Name = "备注")]
		public virtual string Remark { get; set; }
		[Display(Name = "数据源")]
		public virtual string DataSource { get; set; }
		[Display(Name = "报表文件")]
		public virtual string FileName { get; set; }
		[Display(Name = "状态")]
		public virtual string Status { get; set; }
		[Display(Name = "创建人")]
		public virtual string CreatePerson { get; set; }
		[Display(Name = "创建时间")]
		public virtual Nullable<System.DateTime> CreateTime { get; set; }
		[Display(Name = "修改人")]
		public virtual string ModifyPerson { get; set; }
		[Display(Name = "修改时间")]
		public virtual Nullable<System.DateTime> ModifyTime { get; set; }
		[Display(Name = "数据源类型：1-SQL语句；2-存储过程")]
		public virtual Nullable<int> DataSourceType { get; set; }
		}
}