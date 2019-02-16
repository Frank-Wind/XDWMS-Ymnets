﻿using Apps.Common;
using Apps.Models;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System;
using System.IO;
using LinqToExcel;
using ClosedXML.Excel;
using Apps.Models.WMS;
using System.Data;
using System.Data.Entity.Infrastructure;
using System.Dynamic;

namespace Apps.BLL.WMS
{
    public  partial class WMS_ReportBLL
    {
        /// <summary>
        /// 获取当前报表的数据源
        /// </summary>
        /// <returns></returns>
        public DataSet GetDataSource(WMS_ReportModel report, List<WMS_ReportParamModel> listParam)
        {
			return m_Rep.GetDataSource(report, listParam);
		}

        public List<ExpandoObject> GetFeedList(ref GridPager pager)
        {
            using (DBContainer db = new DBContainer())
            {
                DbRawSqlQuery<ExpandoObject> query = db.Database.SqlQuery<ExpandoObject>(@"SELECT  * from V_WMS_FeedList");
                
                //启用通用列头过滤
                pager.totalRows = query.Count();

                try
                {
                    //排序
                    //IQueryable<ExpandoObject> queryData = LinqHelper.SortingAndPaging(query.AsQueryable(), pager.sort, pager.order, pager.page, pager.rows);
                    return query.ToList();
                }
                catch (Exception ex)
                {

                    throw ex;
                }
            }
        }
    }
 }

